;BleskOS

%define NO_DEVICE 0
%define UNINITALIZED_DEVICE 1
%define INITALIZED_DEVICE 2

%define DATA_TOGGLE_0 0x00000000
%define DATA_TOGGLE_1 0x80000000
%define SETUP_PACKET 0x00000E80
%define OUT_PACKET 0x00000C80
%define IN_PACKET 0x00000D80
%define NO_POINTER 0x1
%define NO_MULTIPLY 0x40000000
%define CONTROL_TRANSFER 0x8040E000
%define BULK_TRANSFER 0x8200E000
%define EHCI_TRANSFER_LENGTH(x) (x << 16)

%macro EHCI_CREATE_QUEUE_HEAD 1
 mov dword [MEMORY_EHCI+0], MEMORY_EHCI | 0x2
 mov dword [MEMORY_EHCI+4], %1
 mov dword [MEMORY_EHCI+8], NO_MULTIPLY
 mov dword [MEMORY_EHCI+12], 0x0
 mov dword [MEMORY_EHCI+16], MEMORY_EHCI+0x100 ;pointer to TD
 mov dword [MEMORY_EHCI+20], 0x0
 mov dword [MEMORY_EHCI+24], 0x0
 mov dword [MEMORY_EHCI+28], 0x0
 mov dword [MEMORY_EHCI+32], 0x0
%endmacro

%macro EHCI_CREATE_TD 5
 mov dword [%1+0], %2
 mov dword [%1+4], %3
 mov dword [%1+8], %4
 mov dword [%1+12], %5
 mov dword [%1+16], 0
 mov dword [%1+20], 0
 mov dword [%1+24], 0
 mov dword [%1+28], 0
 mov dword [%1+32], 0
 mov dword [%1+36], 0
 mov dword [%1+40], 0
 mov dword [%1+44], 0
 mov dword [%1+48], 0
%endmacro

ehci_base dd 0
ehci_oper_base dd 0
ehci_port_base dd 0
ehci_port_number dd 0
ehci_number_of_ports dd 0

ehci_address dd 0
ehci_endpoint_bulk_in dd 0
ehci_endpoint_bulk_out dd 0
ehci_transfer_length dd 0
ehci_transfer_pointer dd 0
ehci_data_toggle dd 0
ehci_td_pointer dd 0

ehci_device_type dd 0
ehci_endpoint_1_type dw 0
ehci_endpoint_1_value dw 0
ehci_endpoint_2_type dw 0
ehci_endpoint_2_value dw 0
ehci_endpoint_3_type dw 0
ehci_endpoint_3_value dw 0

%macro EHCI_WRITE_CMD 1
 MMIO_OUTD ehci_oper_base, 0x0, %1
%endmacro

%macro EHCI_WRITE_STS 1
 MMIO_OUTD ehci_oper_base, 0x4, %1
%endmacro

%macro EHCI_DISABLE_INTERRUPTS 0
 MMIO_OUTD ehci_oper_base, 0x8, 0
%endmacro

%macro EHCI_SET_FRAME 1
 MMIO_OUTD ehci_oper_base, 0xC, %1
%endmacro

%macro EHCI_SET_SEGMENT 0
 MMIO_OUTD ehci_oper_base, 0x10, 0x00000000
%endmacro

%macro EHCI_SET_PERIODIC_LIST 1
 MMIO_OUTD ehci_oper_base, 0x14, %1
%endmacro

%macro EHCI_SET_ASYNC_LIST 1
 MMIO_OUTD ehci_oper_base, 0x18, %1
%endmacro

%macro EHCI_SET_FLAG 0
 MMIO_OUTD ehci_oper_base, 0x40, 1
%endmacro

%macro EHCI_SELECT_PORT 0
 mov ebp, dword [ehci_oper_base]
 mov eax, dword [ehci_port_number]
 mov ebx, 4
 mul ebx
 add eax, 0x44
 add ebp, eax
 mov dword [ehci_port_base], ebp
%endmacro

%macro EHCI_READ_PORT 0
 mov ebp, dword [ehci_port_base]
 mov eax, dword [ebp]
%endmacro

%macro EHCI_WRITE_PORT 1
 mov ebp, dword [ehci_port_base]
 mov dword [ebp], %1
%endmacro

ehci_set_controller_values:
 cmp dword [ehci_base], 0
 je .done

 ;calculate number of ports
 MMIO_IND ehci_base, 0x4
 mov dword [ehci_number_of_ports], 0
 mov byte [ehci_number_of_ports], al

 ;get operation registers base
 mov eax, dword [ehci_base]
 mov dword [ehci_oper_base], eax
 mov ebx, 0
 mov bl, byte [eax] ;get offset
 add dword [ehci_oper_base], ebx

 .done:
 ret

init_ehci:
 cmp dword [ehci_base], 0
 je .done

 call ehci_set_controller_values

 ;initalize controller
 EHCI_WRITE_CMD 0x00080002 ;reset
 WAIT 50
 EHCI_WRITE_CMD 0x00080000 ;stop reset
 EHCI_SET_SEGMENT
 EHCI_DISABLE_INTERRUPTS
 EHCI_SET_FRAME 0
 EHCI_SET_PERIODIC_LIST MEMORY_EHCI+0x10000
 EHCI_SET_ASYNC_LIST MEMORY_EHCI
 EHCI_WRITE_STS 0x3F ;clear status
 EHCI_WRITE_CMD 0x00080001 ;run
 EHCI_SET_FLAG

 ;power ports
 mov ebp, dword [ehci_base]
 add ebp, 0x44
 mov ecx, dword [ehci_number_of_ports]
 .set_power_port:
  mov eax, dword [ebp]
  or eax, 0x1000
  mov dword [ebp], eax

  add ebp, 0x4 ;next port
 loop .set_power_port
 WAIT 50

 .done:
 ret

ehci_detect_devices:
 call ehci_set_controller_values

 mov dword [ehci_port_number], 0
 mov ecx, dword [ehci_number_of_ports]
 .detect_devices:
 push ecx
  call ehci_detect_device
  inc dword [ehci_port_number]
 pop ecx
 loop .detect_devices

 .done:
 ret

ehci_detect_device:
 EHCI_SELECT_PORT

 ;get status
 EHCI_READ_PORT
 and eax, 0x1
 cmp eax, NO_DEVICE
 je .no_device

 ;is device initalized?
 EHCI_READ_PORT
 and eax, 0x2
 cmp eax, 0x0
 je .done

 ;initalize device
 EHCI_WRITE_PORT 0x1100 ;reset device
 WAIT 6
 EHCI_WRITE_PORT 0x1002 ;remove reset and clear status change
 WAIT 3

 ;if device is not enabled it means that it is low speed device
 EHCI_READ_PORT
 and eax, 0x4
 cmp eax, 0x4
 jne .low_speed_device

 ;initalize high speed device
 call ehci_device_set_address
 call ehci_device_read_descriptor
 jmp .done

 .low_speed_device:
 EHCI_WRITE_PORT 0x3000 ;pass to companion controller
 jmp .done

 .no_device:
 ;mov eax, dword [ehci_base]
 ;mov dword [msd_usb_controller_base], eax
 ;mov eax, dword [ehci_port_number]
 ;inc eax
 ;mov byte [msd_usb_controller_address], al
 ;call msd_remove_device ;if was some msd connected here

 .done:
 ret

ehci_device_set_address:
 ;queue head
 EHCI_CREATE_QUEUE_HEAD CONTROL_TRANSFER

 ;SETUP transfer descriptor
 EHCI_CREATE_TD MEMORY_EHCI+0x100, MEMORY_EHCI+0x200, NO_POINTER, (SETUP_PACKET | EHCI_TRANSFER_LENGTH(8) | DATA_TOGGLE_0), MEMORY_EHCI+0x300
 ;request
 mov dword [MEMORY_EHCI+0x300+0], 0x00000500
 mov dword [MEMORY_EHCI+0x300+4], 0x00000000
 mov eax, dword [ehci_port_number]
 inc eax ;port 0 have address 1
 mov dword [ehci_address], eax
 mov byte [MEMORY_EHCI+0x300+2], al

 ;IN transfer descriptor
 EHCI_CREATE_TD MEMORY_EHCI+0x200, NO_POINTER, NO_POINTER, (IN_PACKET | EHCI_TRANSFER_LENGTH(0) | DATA_TOGGLE_1), 0x0

 ;start transfer
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x200+8
 call ehci_transfer_queue_head

 ret

ehci_device_read_descriptor:
 ;clear buffer
 mov esi, MEMORY_EHCI+0x800
 mov ecx, 0xFF
 .clear_buffer:
  mov dword [esi], 0
  add esi, 4
 loop .clear_buffer

 ;calculate address
 mov eax, dword [ehci_port_number]
 inc eax
 mov dword [ehci_address], eax

 ;queue head
 mov eax, CONTROL_TRANSFER
 or eax, dword [ehci_address]
 EHCI_CREATE_QUEUE_HEAD eax

 ;SETUP transfer descriptor
 EHCI_CREATE_TD MEMORY_EHCI+0x100, MEMORY_EHCI+0x200, NO_POINTER, (SETUP_PACKET | EHCI_TRANSFER_LENGTH(8) | DATA_TOGGLE_0), MEMORY_EHCI+0x700
 ;request
 mov dword [MEMORY_EHCI+0x700+0], 0x02000680
 mov dword [MEMORY_EHCI+0x700+4], 0x00FF0000
 ;IN transfers descriptor
 EHCI_CREATE_TD MEMORY_EHCI+0x200, MEMORY_EHCI+0x300, MEMORY_EHCI+0x600, (IN_PACKET | EHCI_TRANSFER_LENGTH(64) | DATA_TOGGLE_1), MEMORY_EHCI+0x800
 EHCI_CREATE_TD MEMORY_EHCI+0x300, MEMORY_EHCI+0x400, MEMORY_EHCI+0x600, (IN_PACKET | EHCI_TRANSFER_LENGTH(64) | DATA_TOGGLE_0), MEMORY_EHCI+0x840
 EHCI_CREATE_TD MEMORY_EHCI+0x400, MEMORY_EHCI+0x500, MEMORY_EHCI+0x600, (IN_PACKET | EHCI_TRANSFER_LENGTH(64) | DATA_TOGGLE_1), MEMORY_EHCI+0x880
 EHCI_CREATE_TD MEMORY_EHCI+0x500, MEMORY_EHCI+0x600, MEMORY_EHCI+0x600, (IN_PACKET | EHCI_TRANSFER_LENGTH(64) | DATA_TOGGLE_0), MEMORY_EHCI+0x8C0
 ;OUT transfer descriptor
 EHCI_CREATE_TD MEMORY_EHCI+0x600, NO_POINTER, NO_POINTER, (OUT_PACKET | EHCI_TRANSFER_LENGTH(0) | DATA_TOGGLE_1), 0x0

 ;start transfer
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x600+8
 call ehci_transfer_queue_head

 ;parse descriptor
 mov esi, MEMORY_EHCI+0x800
 call parse_usb_descriptor

 mov eax, dword [usb_descriptor+13]
 cmp eax, 0x00500608
 je .mass_storage_device
 jmp .unknown_device

 .mass_storage_device:
 PSTR 'USB Mass Storage', mass_storage_str
 mov al, byte [usb_descriptor+10]
 call ehci_set_configuration
 mov al, byte [usb_descriptor+11]
 mov bl, byte [usb_descriptor+12]
 call ehci_set_interface
 mov al, byte [usb_descriptor+11]
 call ehci_soft_reset

 mov esi, mass_storage_devices
 mov dword [msd_number], 0
 mov ecx, 5
 .find_free_msd_item:
  cmp dword [esi+7], 0
  je .free_msd_item
  add esi, 16
  inc dword [msd_number]
 loop .find_free_msd_item
 jmp .done ;five msd are connected now

 .free_msd_item:
 mov eax, dword [ehci_base]
 mov dword [esi], eax ;save base address
 mov eax, dword [ehci_address]
 mov byte [esi+4], al ;save device address
 mov al, byte [usb_descriptor+17] ;out endpoint
 mov byte [esi+5], al
 mov al, byte [usb_descriptor+18] ;in endpoint
 mov byte [esi+6], al

 .init_msd:
 mov word [esi+7], 0x1 ;uninitalized state
 call select_msd
 call msd_init

 .done:
 ret

 .unknown_device:
 PHEX eax
 ret

ehci_soft_reset:
 ;request
 mov dword [MEMORY_EHCI+0x300+0], 0x00000221
 mov dword [MEMORY_EHCI+0x300+4], 0x00000000
 mov byte [MEMORY_EHCI+0x300+4], al ;interface number

 ;transfer
 mov eax, CONTROL_TRANSFER
 or eax, dword [ehci_address]
 EHCI_CREATE_QUEUE_HEAD eax
 EHCI_CREATE_TD MEMORY_EHCI+0x100, MEMORY_EHCI+0x200, NO_POINTER, (SETUP_PACKET | EHCI_TRANSFER_LENGTH(8) | DATA_TOGGLE_0), MEMORY_EHCI+0x300
 EHCI_CREATE_TD MEMORY_EHCI+0x200, NO_POINTER, NO_POINTER, (IN_PACKET | EHCI_TRANSFER_LENGTH(0) | DATA_TOGGLE_1), 0x0
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x200+8
 call ehci_transfer_queue_head

 ret

ehci_set_configuration:
 ;request
 mov dword [MEMORY_EHCI+0x300+0], 0x00000900
 mov dword [MEMORY_EHCI+0x300+4], 0x00000000
 mov byte [MEMORY_EHCI+0x300+2], al ;configuration number

 ;transfer
 mov eax, CONTROL_TRANSFER
 or eax, dword [ehci_address]
 EHCI_CREATE_QUEUE_HEAD eax
 EHCI_CREATE_TD MEMORY_EHCI+0x100, MEMORY_EHCI+0x200, NO_POINTER, (SETUP_PACKET | EHCI_TRANSFER_LENGTH(8) | DATA_TOGGLE_0), MEMORY_EHCI+0x300
 EHCI_CREATE_TD MEMORY_EHCI+0x200, NO_POINTER, NO_POINTER, (IN_PACKET | EHCI_TRANSFER_LENGTH(0) | DATA_TOGGLE_1), 0x0
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x200+8
 call ehci_transfer_queue_head

 ret

ehci_set_interface:
 ;request
 mov dword [MEMORY_EHCI+0x300+0], 0x00000B01
 mov dword [MEMORY_EHCI+0x300+4], 0x00000000
 mov byte [MEMORY_EHCI+0x300+4], al ;interface number
 mov byte [MEMORY_EHCI+0x300+2], bl ;alternative interface number

 ;transfer
 mov eax, CONTROL_TRANSFER
 or eax, dword [ehci_address]
 EHCI_CREATE_QUEUE_HEAD eax
 EHCI_CREATE_TD MEMORY_EHCI+0x100, MEMORY_EHCI+0x200, NO_POINTER, (SETUP_PACKET | EHCI_TRANSFER_LENGTH(8) | DATA_TOGGLE_0), MEMORY_EHCI+0x300
 EHCI_CREATE_TD MEMORY_EHCI+0x200, NO_POINTER, NO_POINTER, (IN_PACKET | EHCI_TRANSFER_LENGTH(0) | DATA_TOGGLE_1), 0x0
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x200+8
 call ehci_transfer_queue_head

 ret

ehci_transfer_bulk_in:
 ;queue head
 mov eax, dword [ehci_endpoint_bulk_in]
 shl eax, 8
 or eax, dword [ehci_address]
 or eax, BULK_TRANSFER
 EHCI_CREATE_QUEUE_HEAD eax

 ;OUT transfer descriptor
 mov eax, dword [ehci_transfer_length]
 shl eax, 16
 or eax, IN_PACKET
 or eax, dword [ehci_data_toggle]
 mov ebx, dword [ehci_transfer_pointer]
 EHCI_CREATE_TD MEMORY_EHCI+0x100, NO_POINTER, NO_POINTER, eax, ebx
 and ebx, 0xFFFFF000
 add ebx, 0x1000
 mov dword [MEMORY_EHCI+0x100+16], ebx ;pointer to next part of buffer

 ;start transfer
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x100+8
 call ehci_transfer_queue_head

 ret

ehci_transfer_bulk_out:
 ;queue head
 mov eax, dword [ehci_endpoint_bulk_out]
 shl eax, 8
 or eax, dword [ehci_address]
 or eax, BULK_TRANSFER
 EHCI_CREATE_QUEUE_HEAD eax

 ;OUT transfer descriptor
 mov eax, dword [ehci_transfer_length]
 shl eax, 16
 or eax, OUT_PACKET
 or eax, dword [ehci_data_toggle]
 mov ebx, dword [ehci_transfer_pointer]
 EHCI_CREATE_TD MEMORY_EHCI+0x100, NO_POINTER, NO_POINTER, eax, ebx
 and ebx, 0xFFFFF000
 add ebx, 0x1000
 mov dword [MEMORY_EHCI+0x100+16], ebx ;pointer to next part of buffer

 ;start transfer
 mov dword [ehci_td_pointer], MEMORY_EHCI+0x100+8
 call ehci_transfer_queue_head

 ret

ehci_transfer_queue_head:
 EHCI_WRITE_CMD 0x00080021

 mov edi, dword [ehci_td_pointer]
 mov dword [ticks], 0
 .wait_for_transfer:
  mov eax, dword [edi]
  and eax, 0x80
  cmp eax, 0
  je .transfer_is_complete
 cmp dword [ticks], 500 ;max one second
 jnge .wait_for_transfer

 .transfer_is_complete:
 EHCI_WRITE_CMD 0x00080001

 mov eax, dword [edi] ;save state of transfer

 ret
