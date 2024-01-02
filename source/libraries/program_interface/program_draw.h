//BleskOS

/*
* MIT License
* Copyright (c) 2023-2024 Vendelín Slezák
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#define COLUMN_OF_FIRST_BUTTON_ON_BOTTOM_LINE 8+10*8+8

#define PROGRAM_INTERFACE_TOP_LINE_HEIGTH 21
#define PROGRAM_INTERFACE_BOTTOM_LINE_HEIGTH 20

void draw_program_interface(byte_t *program_name, byte_t *down_string, dword_t border_color, dword_t background_color);
void draw_dialog_yes_no(byte_t *string);
void draw_bottom_line_button(byte_t *string, dword_t click_zone);
void draw_menu_list(byte_t *items_string, dword_t x, dword_t click_zone);