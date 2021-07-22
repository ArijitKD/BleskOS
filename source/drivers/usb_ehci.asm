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
%define BULK_TRANSFER 0x8040E000
%macro EHCI_TD_NO_POINTERS 1
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

ehci_device_type dd 0
ehci_endpoint_1_type dw 0
ehci_endpoint_1_value dw 0
ehci_endpoint_2_type dw 0
ehci_endpoint_2_value dw 0
ehci_endpoint_3_type dw 0
ehci_endpoint_3_value dw 0

%macro EHCI_WRITE_CMD 1
 mov ebp, dword [ehci_oper_base]
 mov dword [ebp], %1
%endmacro

%macro EHCI_WRITE_STS 1
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x04
 mov dword [ebp], %1
%endmacro

%macro EHCI_DISABLE_INTERRUPTS 0
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x08
 mov dword [ebp], 0
%endmacro

%macro EHCI_SET_FRAME 1
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x0C
 mov dword [ebp], %1
%endmacro

%macro EHCI_SET_SEGMENT 0
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x10
 mov dword [ebp], 0x00000000
%endmacro

%macro EHCI_SET_PERIODIC_LIST 1
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x14
 mov dword [ebp], %1
%endmacro

%macro EHCI_SET_ASYNC_LIST 1
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x18
 mov dword [ebp], %1
%endmacro

%macro EHCI_SET_FLAG 0
 mov ebp, dword [ehci_oper_base]
 add ebp, 0x40
 mov dword [ebp], 1
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

%macro EHCI_TRANSFER_QUEUE_HEAD 2
 EHCI_WRITE_CMD 0x00080021
 mov dword [ticks], 0
 .wait_for_transfer:
  mov eax, dword [%1]
  and eax, 0x80
  cmp eax, 0
  je .transfer_is_complete
 cmp dword [ticks], %2
 jl .wait_for_transfer
 PSTR 'EHCI: error with transfer', ehci_error_str

 .transfer_is_complete:
 EHCI_WRITE_CMD 0x00080001
%endmacro

init_ehci:
 cmp dword [ehci_base], 0
 je .done

 PSTR 'EHCI port', ehci_str_up
 mov ebp, dword [ehci_base]
 add ebp, 0x04
 mov eax, dword [ebp]
 mov dword [ehci_number_of_ports], 0
 mov byte [ehci_number_of_ports], al

 ;get operation registers base
 mov eax, dword [ehci_base]
 mov dword [ehci_oper_base], eax
 mov ebx, 0
 mov bl, byte [eax] ;get offset
 add dword [ehci_oper_base], ebx

 ;initalize controller
 EHCI_WRITE_CMD 0x00080000
 EHCI_WRITE_CMD 0x2 ;reset
 WAIT 50
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

 ;detect devices
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
 je .done

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
 EHCI_READ_PORT
 and eax, 0x4
 cmp eax, 0x4
 jne .low_speed_device ;device is not enabled
 ;high speed device
 call ehci_device_set_address
 call ehci_device_read_configuration
 jmp .done

 .low_speed_device:
 EHCI_WRITE_PORT 0x3000 ;pass to companion controller

 .done:
 ret

ehci_device_set_address:
 ;queue head
 mov dword [MEMORY_EHCI+0], MEMORY_EHCI | 0x2
 mov dword [MEMORY_EHCI+4], CONTROL_TRANSFER
 mov dword [MEMORY_EHCI+8], NO_MULTIPLY
 mov dword [MEMORY_EHCI+12], 0x0
 mov dword [MEMORY_EHCI+16], MEMORY_EHCI+0x100 ;pointer to TD
 mov dword [MEMORY_EHCI+20], 0x0
 mov dword [MEMORY_EHCI+24], 0x0

 ;SETUP transfer descriptor
 mov dword [MEMORY_EHCI+0x100+0], MEMORY_EHCI+0x200 ;pointer to next TD
 mov dword [MEMORY_EHCI+0x100+4], NO_POINTER
 mov dword [MEMORY_EHCI+0x100+8], SETUP_PACKET | (8 << 16) | DATA_TOGGLE_0 ;transfer 8 bytes
 mov dword [MEMORY_EHCI+0x100+12], MEMORY_EHCI+0x300 ;pointer to request
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x100

 ;IN transfer descriptor
 mov dword [MEMORY_EHCI+0x200+0], NO_POINTER
 mov dword [MEMORY_EHCI+0x200+4], NO_POINTER
 mov dword [MEMORY_EHCI+0x200+8], 0x80000D80 ;transfer 0 bytes
 mov dword [MEMORY_EHCI+0x200+12], 0x0
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x200

 ;request
 mov dword [MEMORY_EHCI+0x300+0], 0x00000500
 mov dword [MEMORY_EHCI+0x300+4], 0x00000000
 mov eax, dword [ehci_port_number]
 inc eax ;port 0 have address 1
 mov dword [ehci_address], eax
 mov byte [MEMORY_EHCI+0x300+2], al

 ;start transfer
 EHCI_TRANSFER_QUEUE_HEAD MEMORY_EHCI+0x200+8, 20

 ret

ehci_device_read_configuration:
 mov esi, MEMORY_EHCI+0x500
 mov ecx, 16
 .clear_buffer:
  mov dword [esi], 0
  add esi, 4
 loop .clear_buffer

 ;queue head
 mov dword [MEMORY_EHCI+0], MEMORY_EHCI | 0x2
 mov eax, CONTROL_TRANSFER
 or eax, dword [ehci_address]
 mov dword [MEMORY_EHCI+4], eax
 mov dword [MEMORY_EHCI+8], NO_MULTIPLY
 mov dword [MEMORY_EHCI+12], 0x0
 mov dword [MEMORY_EHCI+16], MEMORY_EHCI+0x100 ;pointer to TD
 mov dword [MEMORY_EHCI+20], 0x0
 mov dword [MEMORY_EHCI+24], 0x0

 ;SETUP transfer descriptor
 mov dword [MEMORY_EHCI+0x100+0], MEMORY_EHCI+0x200 ;pointer to next TD
 mov dword [MEMORY_EHCI+0x100+4], NO_POINTER
 mov dword [MEMORY_EHCI+0x100+8], SETUP_PACKET | (8 << 16) | DATA_TOGGLE_0 ;transfer 8 bytes
 mov dword [MEMORY_EHCI+0x100+12], MEMORY_EHCI+0x400 ;pointer to buffer
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x100

 ;IN transfer descriptor
 mov dword [MEMORY_EHCI+0x200+0], MEMORY_EHCI+0x300 ;pointer to next TD
 mov dword [MEMORY_EHCI+0x200+4], NO_POINTER
 mov dword [MEMORY_EHCI+0x200+8], IN_PACKET | (64 << 16) | DATA_TOGGLE_1 ;transfer 64 bytes
 mov dword [MEMORY_EHCI+0x200+12], MEMORY_EHCI+0x500 ;pointer to request
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x200

 ;OUT transfer descriptor
 mov dword [MEMORY_EHCI+0x300+0], NO_POINTER
 mov dword [MEMORY_EHCI+0x300+4], NO_POINTER
 mov dword [MEMORY_EHCI+0x300+8], OUT_PACKET | DATA_TOGGLE_1 ;transfer 0 bytes
 mov dword [MEMORY_EHCI+0x300+12], 0x0 ;pointer to buffer
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x300

 ;request
 mov dword [MEMORY_EHCI+0x400+0], 0x02000680
 mov dword [MEMORY_EHCI+0x400+4], 0x00400000

 ;start transfer
 EHCI_TRANSFER_QUEUE_HEAD MEMORY_EHCI+0x300+8, 40

 ;parse class, subclass and progif
 mov eax, dword [MEMORY_EHCI+0x500+14]
 and eax, 0x00FFFFFF
 mov dword [ehci_device_type], eax

 cmp eax, 0x00500608
 je .mass_storage_device

 jmp .unknown_device

 .mass_storage_device:
 PSTR 'USB Mass Storage', mass_storage_str

 mov eax, dword [ehci_address]
 dec eax ;address 1 is port 0
 mov ebx, 8 ;msd item have 8 bytes
 mul ebx
 add eax, mass_storage_devices
 mov esi, eax

 ;parse endpoints
 mov ax, word [MEMORY_EHCI+0x500+20]
 mov word [ehci_endpoint_1_type], ax
 and word [ehci_endpoint_1_type], 0x0380
 mov word [ehci_endpoint_1_value], ax
 and word [ehci_endpoint_1_value], 0x000F

 cmp word [ehci_endpoint_1_type], 0x0200
 jne .if_msd_endpoint_1_bulk_out
  mov al, byte [ehci_endpoint_1_value]
  mov byte [esi+2], al
 .if_msd_endpoint_1_bulk_out:

 cmp word [ehci_endpoint_1_type], 0x0280
 jne .if_msd_endpoint_1_bulk_in
  mov al, byte [ehci_endpoint_1_value]
  mov byte [esi+3], al
 .if_msd_endpoint_1_bulk_in:

 mov ax, word [MEMORY_EHCI+0x500+27]
 mov word [ehci_endpoint_2_type], ax
 and word [ehci_endpoint_2_type], 0x0380
 mov word [ehci_endpoint_2_value], ax
 and word [ehci_endpoint_2_value], 0x000F

 cmp word [ehci_endpoint_2_type], 0x0200
 jne .if_msd_endpoint_2_bulk_out
  mov al, byte [ehci_endpoint_2_value]
  mov byte [esi+2], al
 .if_msd_endpoint_2_bulk_out:

 cmp word [ehci_endpoint_2_type], 0x0280
 jne .if_msd_endpoint_2_bulk_in
  mov al, byte [ehci_endpoint_2_value]
  mov byte [esi+3], al
 .if_msd_endpoint_2_bulk_in:

 cmp byte [MEMORY_EHCI+0x500+33], 0x05 ;is endpoint present
 jne .init_msd
 mov ax, word [MEMORY_EHCI+0x500+34]
 mov word [ehci_endpoint_3_type], ax
 and word [ehci_endpoint_3_type], 0x0380
 mov word [ehci_endpoint_3_value], ax
 and word [ehci_endpoint_3_value], 0x000F

 cmp word [ehci_endpoint_3_type], 0x0200
 jne .if_msd_endpoint_3_bulk_out
  mov al, byte [ehci_endpoint_3_value]
  mov byte [esi+2], al
 .if_msd_endpoint_3_bulk_out:

 cmp word [ehci_endpoint_3_type], 0x0280
 jne .if_msd_endpoint_3_bulk_in
  mov al, byte [ehci_endpoint_3_value]
  mov byte [esi+3], al
 .if_msd_endpoint_3_bulk_in:

 .init_msd:
 mov word [esi], 0x1 ;uninitalized state

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;mov eax, dword [ehci_address]
 ;dec eax ;address 1 is port 0
 ;call usb_select_msd
 ;call usb_msd_init

 .done:
 ret

 .unknown_device:
 PHEX eax
 PSTR 'Unknown USB device', unknown_device_str
 ret

ehci_transfer_bulk_in:
 ;queue head
 mov dword [MEMORY_EHCI+0], MEMORY_EHCI | 0x2
 mov eax, dword [ehci_endpoint_bulk_in]
 shl eax, 8
 or eax, dword [ehci_address]
 or eax, BULK_TRANSFER
 mov dword [MEMORY_EHCI+4], eax
 mov dword [MEMORY_EHCI+8], NO_MULTIPLY
 mov dword [MEMORY_EHCI+12], 0x0
 mov dword [MEMORY_EHCI+16], MEMORY_EHCI+0x100 ;pointer to TD
 mov dword [MEMORY_EHCI+20], 0x0
 mov dword [MEMORY_EHCI+24], 0x0

 ;IN transfer descriptor
 mov dword [MEMORY_EHCI+0x100+0], NO_POINTER
 mov dword [MEMORY_EHCI+0x100+4], NO_POINTER
 mov eax, dword [ehci_transfer_length]
 shl eax, 16
 or eax, IN_PACKET
 mov dword [MEMORY_EHCI+0x100+8], eax
 mov eax, dword [ehci_transfer_pointer]
 mov dword [MEMORY_EHCI+0x100+12], eax ;pointer to buffer
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x100
 and eax, 0xFFFFF000
 add eax, 0x1000
 mov dword [MEMORY_EHCI+0x100+16], eax ;pointer to next part of buffer

 ;start transfer
 EHCI_TRANSFER_QUEUE_HEAD MEMORY_EHCI+0x100+8, 40

 mov eax, dword [MEMORY_EHCI+0x100+8]
 PHEX eax

 ret

ehci_transfer_bulk_out:
 ;queue head
 mov dword [MEMORY_EHCI+0], MEMORY_EHCI | 0x2
 mov eax, dword [ehci_endpoint_bulk_out]
 shl eax, 8
 or eax, dword [ehci_address]
 or eax, BULK_TRANSFER
 mov dword [MEMORY_EHCI+4], eax
 mov dword [MEMORY_EHCI+8], NO_MULTIPLY
 mov dword [MEMORY_EHCI+12], 0x0
 mov dword [MEMORY_EHCI+16], MEMORY_EHCI+0x100 ;pointer to TD
 mov dword [MEMORY_EHCI+20], 0x0
 mov dword [MEMORY_EHCI+24], 0x0

 ;OUT transfer descriptor
 mov dword [MEMORY_EHCI+0x100+0], NO_POINTER
 mov dword [MEMORY_EHCI+0x100+4], NO_POINTER
 mov eax, dword [ehci_transfer_length]
 shl eax, 16
 or eax, OUT_PACKET
 mov dword [MEMORY_EHCI+0x100+8], eax
 mov eax, dword [ehci_transfer_pointer]
 mov dword [MEMORY_EHCI+0x100+12], eax ;pointer to buffer
 EHCI_TD_NO_POINTERS MEMORY_EHCI+0x100
 and eax, 0xFFFFF000
 add eax, 0x1000
 mov dword [MEMORY_EHCI+0x100+16], eax ;pointer to next part of buffer

 ;start transfer
 EHCI_TRANSFER_QUEUE_HEAD MEMORY_EHCI+0x100+8, 40

 mov eax, dword [MEMORY_EHCI+0x100+8]
 PHEX eax

 ret
