//BleskOS

/*
* MIT License
* Copyright (c) 2023-2025 Vendelín Slezák
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

void parse_hid_descriptor(struct hid_entry_t *hid_descriptor, dword_t hid_descriptor_length) {
 struct hid_entry_t *hid_descriptor_end = (struct hid_entry_t *) ((dword_t)hid_descriptor + hid_descriptor_length);

 //reset HID descriptor variables
 clear_memory((dword_t)&parsed_hid, sizeof(parsed_hid));
 dword_t usages_pointer = 0, number_of_outputted_usages_in_usage_page = 0;
 dword_t offset_in_bits = 0, report_count = 0, report_size = 0, usage_page = 0x00, usage_min = 0, usage_max = 0;
 number_of_hid_parsed_entries = 0;

 //log
 l("\n\nHID descriptor");

 //parse all entries
 while(hid_descriptor < hid_descriptor_end) {
  //end
  if(hid_descriptor->long_item.signature == 0) {
   break;
  }

  //parse entry
  if(hid_descriptor->long_item.signature == HID_LONG_ENTRY_SIGNATURE) { //long entry
   //TODO: support for long entry
   l("\nerror: long entry");
  }
  else { //short entry
   //log
   l("\ns: ");

   //get type of entry
   if(hid_descriptor->short_item.type == HID_SHORT_ENTRY_TYPE_MAIN) {
    l("main ");

    if(hid_descriptor->short_item.tag == 0x8) { //insert input
     l("Insert Input");

     //check if this is not called with invalid input
     if(report_count == 0 || report_size == 0) {
      l("\nInvalid Input call");
      return;
     }

     //add entries
     for(dword_t i=0; i<report_count; i++) {
      //check if there are not too many HID entries
      if(number_of_hid_parsed_entries >= MAX_NUMBER_OF_PARSED_HID_ENTRIES) {
       l("\nToo many HID entries");
       return;
      }

      //save entry
      parsed_hid[number_of_hid_parsed_entries].offset_in_bits = offset_in_bits;
      parsed_hid[number_of_hid_parsed_entries].size_in_bits = report_size;
      parsed_hid[number_of_hid_parsed_entries].usage_page = usage_page;
      parsed_hid[number_of_hid_parsed_entries].usage_value = usage_min;

      parsed_hid[number_of_hid_parsed_entries].data.byte_offset = (offset_in_bits / 8);
      parsed_hid[number_of_hid_parsed_entries].data.shift = (offset_in_bits % 8);
      parsed_hid[number_of_hid_parsed_entries].data.mask = (0xFFFFFFFF >> (32 - report_size));

      //move variables
      offset_in_bits += report_size;
      number_of_hid_parsed_entries++;
      number_of_outputted_usages_in_usage_page++;
      if(usage_min < usage_max) {
       usage_min++;
      }
      else {
       //reset usage values
       usage_min = 0;
       usage_max = 0;
      }
     }

     //move usages pointer
     usages_pointer = number_of_hid_parsed_entries;
    }
    else if(hid_descriptor->short_item.tag == 0xA) { //collection
     l("Collection");

     if(hid_descriptor->short_item.data[0] == 0x00) { //physical collection
      l(" Physical");
     }
    }
    else {
     lhs(hid_descriptor->short_item.tag, 2);
    }
   }
   else if(hid_descriptor->short_item.type == HID_SHORT_ENTRY_TYPE_GLOBAL) {
    l("global ");
    if(hid_descriptor->short_item.tag == 0x0) { //usage page
     l("Usage Page");

     //save usage page type
     usage_page = hid_descriptor->short_item.data[0];

     //reset usages
     if(usages_pointer > number_of_outputted_usages_in_usage_page) { //not all usages were outputted
      for(dword_t i=0; i<(usages_pointer - number_of_outputted_usages_in_usage_page); i++) { //delete all unused usages
       parsed_hid[number_of_hid_parsed_entries+i].usage = 0x00;
      }
     }
     usages_pointer = number_of_hid_parsed_entries;
     usage_min = 0;
     usage_max = 0;
    }
    else if(hid_descriptor->short_item.tag == 0x7) { //report size
     l("Report Size");
     report_size = hid_descriptor->short_item.data[0];
    }
    else if(hid_descriptor->short_item.tag == 0x8) { //report ID
     l("Report ID");

     //check if there are not too many HID entries
     if(number_of_hid_parsed_entries >= MAX_NUMBER_OF_PARSED_HID_ENTRIES) {
      l("\nToo many HID entries");
      return;
     }

     //add entry
     parsed_hid[number_of_hid_parsed_entries].offset_in_bits = offset_in_bits;
     parsed_hid[number_of_hid_parsed_entries].size_in_bits = 8;
     parsed_hid[number_of_hid_parsed_entries].usage_page = 0xFF; //reserved entry that we use for Report ID
     parsed_hid[number_of_hid_parsed_entries].usage = 0;
     parsed_hid[number_of_hid_parsed_entries].usage_value = hid_descriptor->short_item.data[0];

     //move variables
     offset_in_bits += 8;
     number_of_hid_parsed_entries++;

     //move usages pointer
     usages_pointer = number_of_hid_parsed_entries;
    }
    else if(hid_descriptor->short_item.tag == 0x9) { //report count
     l("Report Count");
     report_count = hid_descriptor->short_item.data[0];
    }
    else {
     lhs(hid_descriptor->short_item.tag, 2);
    }
   }
   else if(hid_descriptor->short_item.type == HID_SHORT_ENTRY_TYPE_LOCAL) {
    l("local ");
    if(hid_descriptor->short_item.tag == 0x0) { //usage
     l("Usage");

     //check if there are not too many HID entries
     if(usages_pointer >= MAX_NUMBER_OF_PARSED_HID_ENTRIES) {
      l("\nToo many HID entries to save Usages");
      return;
     }

     //check if we can save this Usage
     if(hid_descriptor->short_item.data[0] == HID_GENERIC_DESKTOP_USAGE_X
        || hid_descriptor->short_item.data[0] == HID_GENERIC_DESKTOP_USAGE_Y
        || hid_descriptor->short_item.data[0] == HID_GENERIC_DESKTOP_USAGE_WHEEL) {
      //save Usage
      parsed_hid[usages_pointer].usage = hid_descriptor->short_item.data[0];
      usages_pointer++;
     }     
    }
    else if(hid_descriptor->short_item.tag == 0x1) { //usage min
     l("Usage Min");
     usage_min = hid_descriptor->short_item.data[0];
    }
    else if(hid_descriptor->short_item.tag == 0x2) { //usage max
     l("Usage Max");
     usage_max = hid_descriptor->short_item.data[0];
    }
    else {
     lhs(hid_descriptor->short_item.tag, 2);
    }
   }
   else { //HID_SHORT_ENTRY_TYPE_RESERVED
    l("reserved "); lhs(hid_descriptor->short_item.tag, 2);
   }

   //log data
   if(hid_descriptor->short_item.size > 0) {
    l(" data: ");
    for(dword_t i=0; i<hid_descriptor->short_item.size; i++) {
     lhsw(hid_descriptor->short_item.data[i], 2);
    }
   }
  }

  //move to next entry
  if(hid_descriptor->long_item.signature == HID_LONG_ENTRY_SIGNATURE) { //long entry
   hid_descriptor = (struct hid_entry_t *) ((dword_t)hid_descriptor+3+hid_descriptor->long_item.size_in_bytes);
  }
  else { //short entry
   hid_descriptor = (struct hid_entry_t *) ((dword_t)hid_descriptor+1+hid_descriptor->short_item.size);
  }
 }

 //log parsed hid descriptor
 l("\n\nParsed HID descriptor");
 for(dword_t i=0; i<number_of_hid_parsed_entries; i++) {
  l("\n");
  lvw(parsed_hid[i].offset_in_bits); lvw(parsed_hid[i].size_in_bits);

  l("Usage Page: ");
  if(parsed_hid[i].usage_page == HID_USAGE_PAGE_GENERIC_DESKTOP) {
   l("Generic Desktop");
  }
  else if(parsed_hid[i].usage_page == HID_USAGE_PAGE_BUTTON) {
   l("Button");
  }
  else {
   lhs(parsed_hid[i].usage_page, 2);
  }

  l(" Usage:");
  if(parsed_hid[i].usage_page == HID_USAGE_PAGE_GENERIC_DESKTOP) {
   l(" ");
   
   if(parsed_hid[i].usage == HID_GENERIC_DESKTOP_USAGE_X) {
    l("X");
   }
   else if(parsed_hid[i].usage == HID_GENERIC_DESKTOP_USAGE_Y) {
    l("Y");
   }
   else if(parsed_hid[i].usage == HID_GENERIC_DESKTOP_USAGE_WHEEL) {
    l("Wheel");
   }
   else {
    lhs(parsed_hid[i].usage, 2);
   }
  }
  else {
   l(" ");
   lhs(parsed_hid[i].usage, 2);
  }

  l(" ");
  lv(parsed_hid[i].usage_value);
 }
}

byte_t get_hid_descriptor_entry(byte_t usage_page, byte_t usage, byte_t usage_value) {
 for(dword_t i=0; i<number_of_hid_parsed_entries; i++) {
  if(parsed_hid[i].usage_page == usage_page && parsed_hid[i].usage == usage && parsed_hid[i].usage_value == usage_value) {
   return i;
  }
 }

 return HID_NO_ENTRY_FOUNDED;
}

dword_t parse_value_from_hid_packet(dword_t *packet, struct hid_entry_data_t hid_entry) {
 packet = (dword_t *) ((dword_t)packet + hid_entry.byte_offset);
 return ((*packet >> hid_entry.shift) & hid_entry.mask);
}