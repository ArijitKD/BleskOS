//BleskOS

/*
* MIT License
* Copyright (c) 2023-2024 Vendelín Slezák, defdefred
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

void initalize_performance_rating(void) {

}

void performance_rating(void) {
	redraw_performance_rating();

	while(1) {
		wait_for_user_input();
		move_mouse_cursor();

		dword_t click_value = get_mouse_cursor_click_board_value();
  if(mouse_click_button_state==MOUSE_CLICK && click_value==PERFORMANCE_RATING_CLICK_ZONE_BACK) {
   return;
  }

		switch (keyboard_value) {
			case KEY_UP:
				if (PERFORMANCE_RATING_CURRENT_TASK > 0) { PERFORMANCE_RATING_CURRENT_TASK--; };
				redraw_performance_rating();
				break;
			case KEY_DOWN:
				if (PERFORMANCE_RATING_CURRENT_TASK < PERFORMANCE_RATING_NBTASK-1) { PERFORMANCE_RATING_CURRENT_TASK++; };
				redraw_performance_rating();
				break;
			case KEY_ENTER:
    message_window("Running task...");
    redraw_screen();
    performance_rating_run_task(PERFORMANCE_RATING_CURRENT_TASK);
				redraw_performance_rating();
				break;
			case KEY_A:
    for (int i=0; i<PERFORMANCE_RATING_NBTASK; i++) {
     message_window("Running tasks...");
     redraw_screen();
     performance_rating_run_task(i);
    }
    redraw_performance_rating();
				break;
			case KEY_PAGE_UP:
				break;
			case KEY_PAGE_DOWN:
				break;
			case KEY_ESC:
				return;
		}
	}
}

void redraw_performance_rating(void) {
	dword_t color;
	clear_screen(0xbb00dd);
 clear_click_board();

	for (int i=0; i<PERFORMANCE_RATING_NBTASK; i++) {
		if ( i == PERFORMANCE_RATING_CURRENT_TASK ) { color=RED; } else { color=BLACK; };
		print(performance_rating_tasks[i].name, 20, 10+i*10, color);
  print_var(performance_rating_tasks[i].result_of_one_test_run, graphic_screen_x_center, 10+i*10, color);
		print_var(performance_rating_tasks[i].result, graphic_screen_x_center+10*8, 10+i*10, color);
	}
 print("Results are time in microseconds for 1x run and 100x runs", 20, 10+PERFORMANCE_RATING_NBTASK*10+10, BLACK);
	print("[ESC] Quit | [ARROWS] Choose | [ENTER] Run | [A] Run all", 0, graphic_screen_y-8, BLACK);
 add_zone_to_click_board(0, graphic_screen_y-8, 11*8, 8, PERFORMANCE_RATING_CLICK_ZONE_BACK);
	redraw_screen();
}

void performance_rating_run_task(dword_t task_number) {
 dword_t sum = 0;

 if(hpet_base!=0) { //we use HPET
  //get average time of 1 run from 10 runs
  for(dword_t i=0; i<10; i++) {
   hpet_reset_counter();
   performance_rating_tasks[task_number].run();
   sum += hpet_return_time_in_microseconds();
  }
  performance_rating_tasks[task_number].result_of_one_test_run = (sum/10);
  
  //get time of 100 runs
  performance_rating_tasks[task_number].result = 0;
  for(dword_t i=0; i<PERFORMANCE_RATING_RUN_COUNT; i++) {
   hpet_reset_counter();
   performance_rating_tasks[task_number].run();
   performance_rating_tasks[task_number].result += hpet_return_time_in_microseconds();
  }
 }
 else { //we use PIT
  //get average time of 1 run from 10 runs
  for(dword_t i=0; i<10; i++) {
   wait(1);
   ticks = 0;
   performance_rating_tasks[task_number].run();
   sum += (ticks*MILISECONDS_PER_ONE_PIT_TICK*1000);
  }
  performance_rating_tasks[task_number].result_of_one_test_run = (sum/10);
  
  //get time of 100 runs
  performance_rating_tasks[task_number].result = 0;
  for(dword_t i=0; i<PERFORMANCE_RATING_RUN_COUNT; i++) {
   wait(1);
   ticks = 0;
   performance_rating_tasks[task_number].run();
   performance_rating_tasks[task_number].result += (ticks*MILISECONDS_PER_ONE_PIT_TICK*1000);
  }
 }
}

void performance_rating_task0() {
 clear_screen(0x123456);
}

void performance_rating_task1() {
 mouse_movement_x = 6;
 move_mouse_cursor();
}

void performance_rating_task2() {
 //TODO
}

void performance_rating_task3() {
 //TODO
}

void performance_rating_task4() {
	redraw_screen();
}

void performance_rating_task5() {
 //TODO
}

void performance_rating_task6() {
 //TODO
}

void performance_rating_task7() {
 //TODO
}