//BleskOS

/*
* MIT License
* Copyright (c) 2023 Vendelín Slezák
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

void pata_select_sector_lba28(word_t base_port, dword_t sector, byte_t number_of_sectors);
void pata_select_sector_lba48(word_t base_port, dword_t sector, byte_t number_of_sectors);
byte_t pata_read(word_t base_port, dword_t sector, byte_t number_of_sectors, dword_t memory);
byte_t pata_write(word_t base_port, dword_t sector, byte_t number_of_sectors, dword_t memory);
byte_t pata_delete(word_t base_port, dword_t sector, byte_t number_of_sectors);