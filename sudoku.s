# a0: pointer to cell
# v0: number of viable candidates in the cell
num_candidates:
	# initialize some counter 
	li $t0, 0

	# load the '.' in for comparison 
	li $t1, 46

	# loop infinitely
	loop:
		# load the byte (0-extended char) that the pointer points to
		lbu $t2, 0($a0)

		# if we have reached the null character, branch to return
		beqz $t2, return

		# if the character that t4 points to is equal to '.' then we branch straight to increment; else we increase counter
		beq $t1, $t2, increment_pointer
		addi $t0, $t0, 1

		increment_pointer:
			# move string pointer up one and increase the loop lower count 
			addi $a0, $a0, 1

		# re-loop
		j loop

	return:
		# move the $t0 which holds to counter to our return register and return that
		move $v0, $t0
		jr $ra



#### Do not move this separator. Place all of your num_candidates code above this line. ####


# a0: pointer to cell
# a1: candidate to eliminate from cell 
rule_out_of_cell:

	# load 46 (the ascii for the '.' into t0)
	li $t0, 46

	# load the word from a1 into t1
	move $t1, $a1

	# we want to decrement because the digit n (1-9) is at pointer element n-1 (0-8)
	addi $t1, $t1, -1

	# move the pointer to the cell up by the (int in a1) -1 positions
	add $a0, $a0, $t1

	# save the ascii-d '.' into the memory that $a0 points to
	sb $t0, 0($a0)
	jr $ra

#### Do not move this separator. Place all of your rule_out_of_cell code above this line, and below previous separator. ###
	


# a0: pointer to board
# v0: number of solved cells
count_solved_cells:	


	# initialize counter that will go to 81 (inclusive); we need to keep this on the stack, so we put it in a saved register
	li $s1, 1

	# this saved register will represent the running sum of solved cells
	li $s0, 0

	for_loop:

		# if our counter is > 81, then we branch to return (because our counter starts at 1)
		bgt $s1, 81, return_val

		# allocate 3 words on the stack
		addi $sp, $sp, -16

		# store the ra, saved register and pointer on the stack
		sw $ra, 0($sp)
		sw $s0, 4($sp)
		sw $a0, 8($sp)
		sw $s1, 12($sp)

		# jal to the is_cell_solved helper
		jal is_cell_solved

		# load the stored register back from the stack
		lw $s0, 4($sp)
		lw $s1, 12($sp)
		
		# add the returned val from the jal to the stored register (because is_cell_solved returns 1 if the cell is solved)
		add $s0, $s0, $v0
		addi $s1, 1

		# load back the ra and pointer
		lw $ra, 0($sp)
		lw $a0, 8($sp)

		# de-allocate stack space
		addi $sp, $sp, 16

		# move pointer up 10 bytes aka one cell 
		addi $a0, $a0, 10

		# re-loop
		j for_loop

return_val:
	# move the saved register to the return register and return it
	move $v0, $s0
	jr $ra



#### Do not move this separator. Place all of your count_solved_cells code above this line, and below previous separator. ###
	
# a0: pointer to board
solve_board:

	# while loop that runs until we have 81 solved cells (aka the board is solved)
	while_loop:

		# allocate space on the stack for the ra and our pointer; then save the ra and pointer onto the stack
		addi $sp, $sp, -8
		sw $ra, 0($sp)
		sw $a0, 4($sp)

		# jal to count_solved_cells
		jal count_solved_cells

		lw $ra, 0($sp)
		lw $a0, 4($sp)
		addi $sp, $sp, 8

		# if this return value is equal to 81, then we have solved the board and should return out
		li $t3, 81
		beq $v0, $t3, return_exit


		# if we reach this, then there exists at least one cell that is unsolved
		# thus, we should loop through all cells

		# currently, our a0 is a pointer to a board and our ra is the corerct ra 

		# initialize counter that will go to 81 (inclusive); we need this on the stack 
		li $s1, 1

		# move address of a0 to our saved register (this will represent which cell we are on in the board); s0 is our running pointer 
		move $s0, $a0

		# for each cell
		for_each_cell:

			# if our counter is > 81, then we branch to return
			bgt $s1, 81, next_while

			# allocate 4 words on the stack
			addi $sp, $sp, -16

			# store the ra, saved register s0 which is the running pointer,  a0 which is the pointer to the start of the board, and s1 (the for loop counter) on the stack
			sw $ra, 0($sp)
			sw $s0, 4($sp)
			sw $a0, 8($sp)
			sw $s1, 12($sp)

			# our running pointer (which cell we are currently checking for if it is solved) becomes the argument for is_cell_solved
			move $a0, $s0

			# jal to the is_cell_solved helper
			jal is_cell_solved


			# load the stored stuff back from the stack
			lw $ra, 0($sp)
			lw $s0, 4($sp)
			lw $a0, 8($sp)
			lw $s1, 12($sp)


			# if the resulting v0 from is_cell_solved is a 0 then we dont need to rule anything out, so we branch to increment our running pointer;
			# else then that cell at s0 is solved, so we should pass that and the pointer to the board to all the rule out functions

			li $t1, 0
			beq $v0, $t1, not_rule_out

				# we want to call each of the rule out functions 

				# save all of our stuff to the stack
				sw $ra, 0($sp)
				sw $s0, 4($sp)
				sw $a0, 8($sp)
				sw $s1, 12($sp)

				# move pointer to solved cell to a1; our a0 should be re-loaded from our stack
				move $a1, $s0
				lw $a0, 8($sp)
				jal rule_out_of_row


				# move pointer to solved cell to a1; our a0 should be re-loaded from our stack
				move $a1, $s0
				lw $a0, 8($sp)
				jal rule_out_of_col


				# move pointer to solved cell to a1; our a0 should be re-loaded from our stack
				move $a1, $s0
				lw $a0, 8($sp)
				jal rule_out_of_box

				# reload info from our stack
				lw $ra, 0($sp)
				lw $s0, 4($sp)
				lw $a0, 8($sp)
				lw $s1, 12($sp)

			not_rule_out:
				# move pointer up 10 bytes aka one cell 
				addi $s0, $s0, 10

				# move our s1 for loop incrementer up by 1
				addi $s1, 1

				# de-allocate stack space
				addi $sp, $sp, 16


				# re-loop
				j for_each_cell

		next_while:
			# we utilized all solved cells for this iteration, but we need to re-loop to see if we have overall solved the board
			j while_loop

	# we have solved the board so we can return to ra
	return_exit:
		jr $ra


#### Do not move this separator. Place all of your solve_board code above this line, and below previous separator. ###

main:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)

	##
	## Testing num_candidates
	##

	la $a0, num_candidates_test_msg
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## 123456789
	## 9
	la $a0, testcell1
	jal num_candidates
	move $s0, $v0
	la $a0, testcell1
	jal print_string
	jal print_newline
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	## should print:
	## 1.34.6789
	## 7
	la $a0, testcell2
	jal num_candidates
	move $s0, $v0
	la $a0, testcell2
	jal print_string
	jal print_newline
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	## should print:
	## .2.4.6.8.
	## 4
	la $a0, testcell3
	jal num_candidates
	move $s0, $v0
	la $a0, testcell3
	jal print_string
	jal print_newline
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	## should print:
	## .....67..
	## 2
	la $a0, testcell4
	jal num_candidates
	move $s0, $v0
	la $a0, testcell4
	jal print_string
	jal print_newline
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	## should print:
	## .........
	## 0
	la $a0, testcell5
	jal num_candidates
	move $s0, $v0
	la $a0, testcell5
	jal print_string
	jal print_newline
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline
	
	##
	## Testing rule_out_of_cell
	##

	la $a0, rule_out_of_cell_test_msg
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## 123456789
	## 12345678.
	la $a0, testcell1
	jal print_string
	jal print_newline
	la $a0, testcell1
	li $a1, 9
	jal rule_out_of_cell
	la $a0, testcell1
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## 1.34.6789
	## 1.34.6789
	la $a0, testcell2
	jal print_string
	jal print_newline
	la $a0, testcell2
	li $a1, 5
	jal rule_out_of_cell
	la $a0, testcell2
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## .2.4.6.8.
	## .2.4.6...
	la $a0, testcell3
	jal print_string
	jal print_newline
	la $a0, testcell3
	li $a1, 8
	jal rule_out_of_cell
	la $a0, testcell3
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## .....67..
	## ......7..
	la $a0, testcell4
	jal print_string
	jal print_newline
	la $a0, testcell4
	li $a1, 6
	jal rule_out_of_cell
	la $a0, testcell4
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	## .........
	## .........
	la $a0, testcell5
	jal print_string
	jal print_newline
	la $a0, testcell5
	li $a1, 1
	jal rule_out_of_cell
	la $a0, testcell5
	jal print_string
	jal print_newline
	jal print_newline
	

	##
	## Testing count_solved_cells
	##

	la $a0, count_solved_cells_test_msg
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 .......8. 123456789 | ....5.... .....6... 123456789 | 123456789 ...4..... 123456789 |
	## | 123456789 ....5.... ..3...... | 123456789 123456789 .2....... | 123456789 ........9 123456789 |
	## | .2....... ......7.. 123456789 | .......8. 1........ 123456789 | 123456789 ..3...... .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | ...4..... 123456789 123456789 | 123456789 123456789 123456789 | ......7.. .2....... ....5.... |
	## | .......8. ..3...... .....6... | 123456789 123456789 123456789 | 123456789 123456789 123456789 |
	## | 123456789 123456789 ......7.. | 1........ ........9 ...4..... | 123456789 123456789 123456789 |
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 123456789 ....5.... | 123456789 .2....... ......7.. | 1........ 123456789 .......8. |
	## | 1........ ........9 123456789 | .....6... 123456789 .......8. | 123456789 123456789 ...4..... |
	## | 123456789 .....6... 123456789 | ...4..... ..3...... 123456789 | 123456789 ....5.... .2....... |
	##  ----------------------------------------------------------------------------------------------- 
	## 40

	la $a0, easyboard1
	jal count_solved_cells
	move $s0, $v0
	la $a0, easyboard1
	jal print_board
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	## should print:
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 1........ 123456789 | .2....... .....6... ........9 | 123456789 ...4..... 123456789 |
	## | 123456789 ........9 123456789 | 123456789 .......8. ..3...... | 1........ 123456789 ......7.. |
	## | 123456789 ....5.... ..3...... | 123456789 123456789 ...4..... | 123456789 .......8. .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 123456789 123456789 | .....6... .2....... .......8. | ......7.. 1........ 123456789 |
	## | 1........ .....6... .......8. | 123456789 123456789 123456789 | 123456789 ........9 .2....... |
	## | ....5.... ......7.. 123456789 | ........9 123456789 1........ | 123456789 123456789 .......8. |
	##  ----------------------------------------------------------------------------------------------- 
	## | .....6... 123456789 ........9 | ...4..... ..3...... 123456789 | .......8. 123456789 123456789 |
	## | 123456789 123456789 1........ | 123456789 123456789 .2....... | .....6... ..3...... ........9 |
	## | ..3...... 123456789 ....5.... | 1........ ........9 123456789 | .2....... 123456789 123456789 |
	##  ----------------------------------------------------------------------------------------------- 
	## 45

	la $a0, easyboard2
	jal count_solved_cells
	move $s0, $v0
	la $a0, easyboard2
	jal print_board
	move $a0, $s0
	jal print_int
	jal print_newline
	jal print_newline

	##
	## Testing solve_board
	##
	
	la $a0, solve_board_test_msg
	jal print_string
	jal print_newline
	jal print_newline

	## should print:
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 .......8. 123456789 | ....5.... .....6... 123456789 | 123456789 ...4..... 123456789 |
	## | 123456789 ....5.... ..3...... | 123456789 123456789 .2....... | 123456789 ........9 123456789 |
	## | .2....... ......7.. 123456789 | .......8. 1........ 123456789 | 123456789 ..3...... .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | ...4..... 123456789 123456789 | 123456789 123456789 123456789 | ......7.. .2....... ....5.... |
	## | .......8. ..3...... .....6... | 123456789 123456789 123456789 | 123456789 123456789 123456789 |
	## | 123456789 123456789 ......7.. | 1........ ........9 ...4..... | 123456789 123456789 123456789 |
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 123456789 ....5.... | 123456789 .2....... ......7.. | 1........ 123456789 .......8. |
	## | 1........ ........9 123456789 | .....6... 123456789 .......8. | 123456789 123456789 ...4..... |
	## | 123456789 .....6... 123456789 | ...4..... ..3...... 123456789 | 123456789 ....5.... .2....... |
	##  ----------------------------------------------------------------------------------------------- 
	##  ----------------------------------------------------------------------------------------------- 
	## | ........9 .......8. 1........ | ....5.... .....6... ..3...... | .2....... ...4..... ......7.. |
	## | .....6... ....5.... ..3...... | ......7.. ...4..... .2....... | .......8. ........9 1........ |
	## | .2....... ......7.. ...4..... | .......8. 1........ ........9 | ....5.... ..3...... .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | ...4..... 1........ ........9 | ..3...... .......8. .....6... | ......7.. .2....... ....5.... |
	## | .......8. ..3...... .....6... | .2....... ......7.. ....5.... | ...4..... 1........ ........9 |
	## | ....5.... .2....... ......7.. | 1........ ........9 ...4..... | .....6... .......8. ..3...... |
	##  ----------------------------------------------------------------------------------------------- 
	## | ..3...... ...4..... ....5.... | ........9 .2....... ......7.. | 1........ .....6... .......8. |
	## | 1........ ........9 .2....... | .....6... ....5.... .......8. | ..3...... ......7.. ...4..... |
	## | ......7.. .....6... .......8. | ...4..... ..3...... 1........ | ........9 ....5.... .2....... |
	##  ----------------------------------------------------------------------------------------------- 
	la $a0, easyboard1
	jal print_board
	la $a0, easyboard1
	jal solve_board
	la $a0, easyboard1
	jal print_board
	jal print_newline
	jal print_newline
	
	## should print:
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 1........ 123456789 | .2....... .....6... ........9 | 123456789 ...4..... 123456789 |
	## | 123456789 ........9 123456789 | 123456789 .......8. ..3...... | 1........ 123456789 ......7.. |
	## | 123456789 ....5.... ..3...... | 123456789 123456789 ...4..... | 123456789 .......8. .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | 123456789 123456789 123456789 | .....6... .2....... .......8. | ......7.. 1........ 123456789 |
	## | 1........ .....6... .......8. | 123456789 123456789 123456789 | 123456789 ........9 .2....... |
	## | ....5.... ......7.. 123456789 | ........9 123456789 1........ | 123456789 123456789 .......8. |
	##  ----------------------------------------------------------------------------------------------- 
	## | .....6... 123456789 ........9 | ...4..... ..3...... 123456789 | .......8. 123456789 123456789 |
	## | 123456789 123456789 1........ | 123456789 123456789 .2....... | .....6... ..3...... ........9 |
	## | ..3...... 123456789 ....5.... | 1........ ........9 123456789 | .2....... 123456789 123456789 |
	##  ----------------------------------------------------------------------------------------------- 
	##  ----------------------------------------------------------------------------------------------- 
	## | .......8. 1........ ......7.. | .2....... .....6... ........9 | ....5.... ...4..... ..3...... |
	## | ...4..... ........9 .....6... | ....5.... .......8. ..3...... | 1........ .2....... ......7.. |
	## | .2....... ....5.... ..3...... | ......7.. 1........ ...4..... | ........9 .......8. .....6... |
	##  ----------------------------------------------------------------------------------------------- 
	## | ........9 ..3...... ...4..... | .....6... .2....... .......8. | ......7.. 1........ ....5.... |
	## | 1........ .....6... .......8. | ..3...... ......7.. ....5.... | ...4..... ........9 .2....... |
	## | ....5.... ......7.. .2....... | ........9 ...4..... 1........ | ..3...... .....6... .......8. |
	##  ----------------------------------------------------------------------------------------------- 
	## | .....6... .2....... ........9 | ...4..... ..3...... ......7.. | .......8. ....5.... 1........ |
	## | ......7.. ...4..... 1........ | .......8. ....5.... .2....... | .....6... ..3...... ........9 |
	## | ..3...... .......8. ....5.... | 1........ ........9 .....6... | .2....... ......7.. ...4..... |
	##  ----------------------------------------------------------------------------------------------- 
	la $a0, easyboard2
	jal print_board
	la $a0, easyboard2
	jal solve_board
	la $a0, easyboard2
	jal print_board
	jal print_newline
	jal print_newline

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
# a0: pointer to board
# a1: pointer to solved cell
rule_out_of_row:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	move $s0, $a0    # s0: pointer to board
 	move $s1, $a1    # s1: pointer to solved cell
	move $a0, $s1    # s2: value of solved cell
 	jal first_candidate
 	move $s2, $v0
	move $a0, $s0    # s3: pointer to base of row
	move $a1, $s1
	jal get_row_base
	move $s3, $v0

	# rule out of each cell in the row
 	addi $a0, $s3, 0
	beq $a0, $s1, rule_out_of_row_cell1
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell1:	
 	addi $a0, $s3, 10
	beq $a0, $s1, rule_out_of_row_cell2
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell2:	
 	addi $a0, $s3, 20
	beq $a0, $s1, rule_out_of_row_cell3
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell3:	
 	addi $a0, $s3, 30
	beq $a0, $s1, rule_out_of_row_cell4
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell4:	
 	addi $a0, $s3, 40
	beq $a0, $s1, rule_out_of_row_cell5
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell5:	
 	addi $a0, $s3, 50
	beq $a0, $s1, rule_out_of_row_cell6
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell6:	
 	addi $a0, $s3, 60
	beq $a0, $s1, rule_out_of_row_cell7
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell7:	
 	addi $a0, $s3, 70
	beq $a0, $s1, rule_out_of_row_cell8
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_row_cell8:	
 	addi $a0, $s3, 80
	beq $a0, $s1, rule_out_of_row_exit
 	move $a1, $s2
 	jal rule_out_of_cell
	
rule_out_of_row_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra

# a0: pointer to board
# a1: pointer to solved cell
rule_out_of_col:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	move $s0, $a0          # s0: pointer to board
 	move $s1, $a1          # s1: pointer to solved cell
	move $a0, $s1          # s2: value of solved cell
 	jal first_candidate
 	move $s2, $v0
	move $a0, $s0          # s3: pointer to base of col
	move $a1, $s1
	jal get_col_base
	move $s3, $v0

	# rule out of each cell in the row
 	addi $a0, $s3, 0
	beq $a0, $s1, rule_out_of_col_cell1
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell1:	
 	addi $a0, $s3, 90
	beq $a0, $s1, rule_out_of_col_cell2
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell2:	
 	addi $a0, $s3, 180
	beq $a0, $s1, rule_out_of_col_cell3
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell3:	
 	addi $a0, $s3, 270
	beq $a0, $s1, rule_out_of_col_cell4
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell4:	
 	addi $a0, $s3, 360
	beq $a0, $s1, rule_out_of_col_cell5
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell5:	
 	addi $a0, $s3, 450
	beq $a0, $s1, rule_out_of_col_cell6
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell6:	
 	addi $a0, $s3, 540
	beq $a0, $s1, rule_out_of_col_cell7
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell7:	
 	addi $a0, $s3, 630
	beq $a0, $s1, rule_out_of_col_cell8
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_col_cell8:	
 	addi $a0, $s3, 720
	beq $a0, $s1, rule_out_of_col_exit
 	move $a1, $s2
 	jal rule_out_of_cell
	
rule_out_of_col_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra


# a0: pointer to board
# a1: pointer to solved cell
rule_out_of_box:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	move $s0, $a0         # s0: pointer to board
 	move $s1, $a1         # s1: pointer to solved cell
	move $a0, $s1         # s2: value of solved cell
 	jal first_candidate
 	move $s2, $v0 
	move $a0, $s0         # s3: pointer to base of box
	move $a1, $s1
	jal get_box_base
	move $s3, $v0

	# rule out of each cell in the box
 	addi $a0, $s3, 0
	beq $a0, $s1, rule_out_of_box_cell1
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell1:	
 	addi $a0, $s3, 10
	beq $a0, $s1, rule_out_of_box_cell2
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell2:	
 	addi $a0, $s3, 20
	beq $a0, $s1, rule_out_of_box_cell3
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell3:	
 	addi $a0, $s3, 90
	beq $a0, $s1, rule_out_of_box_cell4
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell4:	
 	addi $a0, $s3, 100
	beq $a0, $s1, rule_out_of_box_cell5
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell5:	
 	addi $a0, $s3, 110
	beq $a0, $s1, rule_out_of_box_cell6
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell6:	
 	addi $a0, $s3, 180
	beq $a0, $s1, rule_out_of_box_cell7
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell7:	
 	addi $a0, $s3, 190
	beq $a0, $s1, rule_out_of_box_cell8
 	move $a1, $s2
 	jal rule_out_of_cell
rule_out_of_box_cell8:	
 	addi $a0, $s3, 200
	beq $a0, $s1, rule_out_of_box_exit
 	move $a1, $s2
 	jal rule_out_of_cell
	
rule_out_of_box_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra
	

# a0: pointer to board
# a1: pointer to cell
# v0: pointer to base of col containing cell 
get_col_base:
	# t0: cell offset in board
	sub $t0, $a1, $a0
	# t1: col offset, i.e., cell offset % 90
	li $t1, 90
	rem $t1, $t0, $t1
	# v0: pointer to base of col, i.e., board + col offset
	add $v0, $a0, $t1
	jr $ra

# a0: pointer to board
# a1: pointer to cell
# v0: pointer to base of row containing cell 
get_row_base:
	# t0: cell offset in board
	sub $t0, $a1, $a0
	# t1: row offset in board, i.e., cell offset - (cell offset % 90)
	li $t1, 90
	rem $t1, $t0, $t1
	sub $t1, $t0, $t1
	# v0: pointer to base of row, i.e., board + row offset
	add $v0, $a0, $t1
	jr $ra

# a0: pointer to board
# a1: pointer to cell
# v0: pointer to base of box containing cell 
get_box_base:
	# t0: cell offset in board
	sub $t0, $a1, $a0
	# t1: t0 % 270
	li $t1, 270
	rem $t1, $t0, $t1
	# t2: t0 % 90
	li $t2, 90
	rem $t2, $t0, $t2
	# t3: t0 % 30
	li $t3, 30
	rem $t3, $t0, $t3
	# t4: offset of cell in box, i.e., (t1 - t2) + t3
	sub $t4, $t1, $t2
	add $t4, $t4, $t3
	# v0: pointer to base of box, i.e., cell - offset of cell in box
	sub $v0, $a1, $t4
	jr $ra
	

# a0: pointer to board
print_board:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	move $s0, $a0          # s0: pointer to board
	addi $s1, $a0, 810     # s1: end of board
	move $s2, $a0	       # s2: current cell
print_board_top:
	# t1: cell offset
	# if cell offset % 270 == 0, print hsep
	sub $t1, $s2, $s0
	li $t0, 270
	rem $t0, $t1, $t0
	bnez $t0, print_board_skip_hsep
	jal print_hsep
	jal print_newline
print_board_skip_hsep:
	# check to see if end of board
	beq $s2, $s1, print_board_exit
	# if cell offset % 30 == 0, print vsep
	li $t0, 30
	rem $t0, $t1, $t0
	bnez $t0, print_board_skip_vsep
	jal print_vsep
	jal print_space
print_board_skip_vsep:
	# print cell
	move $a0, $s2
	jal print_string
	jal print_space
	# if cell offset % 90 == 80, print another vsep and newline
	li $t0, 90
	rem $t0, $t1, $t0
	li $t1, 80
	bne $t0, $t1, print_board_skip_second_vsep
	jal print_vsep
	jal print_newline
print_board_skip_second_vsep:
	# advance cell pointer and repeat
	addi $s2, $s2, 10
	b print_board_top

print_board_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra

# a0: pointer to cell
# v0: 1 if cell solved, 0 otherwise
is_cell_solved:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# get number of candidates
	jal num_candidates
	# if num candidates, is one, cell is solved
	li $t0, 1	
	beq $v0, $t0, is_cell_solved_true
	b is_cell_solved_false
is_cell_solved_true:
	li $v0, 1
	b is_cell_solved_exit
is_cell_solved_false:
	li $v0, 0
is_cell_solved_exit:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# a0: pointer to cell
# v0: value of first possible digit (if no candidates, returns 0)
first_candidate:
	# v0: value of digit checking
	li $v0, 1
	# keep ascii code for eliminated digit handy
	li $t1, 46
first_candidate_top:
	# t0: pointer to char (a0 + v0 - 1)
	add $t0, $a0, $v0
	addi $t0, $t0, -1
	# load char
	lbu $t0, 0($t0)
	# if end of string, exit having found no viable digits
	beqz $t0, first_candidate_none_found
	# if curr digit not viable (already eliminated), move on to next digit
	beq $t0, $t1, first_candidate_advance
	# else, this is a viable digit, exit
	jr $ra
first_candidate_advance:	
	addi $v0, $v0, 1
	b first_candidate_top
first_candidate_none_found:
	li $v0, 0	
	jr $ra

# prints | 	
print_vsep:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, vsep
	jal print_string
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# prints horizontal line	
print_hsep:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, hsep
	jal print_string
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

print_newline:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, newline
	jal print_string
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

print_space:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, space
	jal print_string
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# a0: integer to print	
print_int:
	li $v0, 1
	syscall
	jr $ra

# a0: string to print	
print_string:	
	li $v0, 4
	syscall
	jr $ra
	
.data

newline:	.asciiz "\n"
vsep:   	.asciiz "|"
hsep:   	.asciiz " ----------------------------------------------------------------------------------------------- "
space:		.asciiz " "

testcell1:	.asciiz "123456789"
testcell2:	.asciiz "1.34.6789"
testcell3:	.asciiz ".2.4.6.8."
testcell4:	.asciiz ".....67.."
testcell5:	.asciiz "........."
	
num_candidates_test_msg:	.asciiz "*** Testing num_candidates ***"
rule_out_of_cell_test_msg:	.asciiz "*** Testing rule_out_of_cell ***"
count_solved_cells_test_msg:	.asciiz "*** Testing count_solved_cells ***"
solve_board_test_msg:		.asciiz "*** Testing solve_board ***"
	
easyboard1:
.asciiz "123456789"
.asciiz ".......8."
.asciiz "123456789"
.asciiz "....5...."
.asciiz ".....6..."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "...4....."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "....5...."
.asciiz "..3......"
.asciiz "123456789"
.asciiz "123456789"
.asciiz ".2......."
.asciiz "123456789"
.asciiz "........9"
.asciiz "123456789"
.asciiz ".2......."
.asciiz "......7.."
.asciiz "123456789"
.asciiz ".......8."
.asciiz "1........"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "..3......"
.asciiz ".....6..."
.asciiz "...4....."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "......7.."
.asciiz ".2......."
.asciiz "....5...."
.asciiz ".......8."
.asciiz "..3......"
.asciiz ".....6..."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "......7.."
.asciiz "1........"
.asciiz "........9"
.asciiz "...4....."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "....5...."
.asciiz "123456789"
.asciiz ".2......."
.asciiz "......7.."
.asciiz "1........"
.asciiz "123456789"
.asciiz ".......8."
.asciiz "1........"
.asciiz "........9"
.asciiz "123456789"
.asciiz ".....6..."
.asciiz "123456789"
.asciiz ".......8."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "...4....."
.asciiz "123456789"
.asciiz ".....6..."
.asciiz "123456789"
.asciiz "...4....."
.asciiz "..3......"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "....5...."
.asciiz ".2......."

easyboard2:
.asciiz "123456789"
.asciiz "1........"
.asciiz "123456789"
.asciiz ".2......."
.asciiz ".....6..."
.asciiz "........9"
.asciiz "123456789"
.asciiz "...4....."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "........9"
.asciiz "123456789"
.asciiz "123456789"
.asciiz ".......8."
.asciiz "..3......"
.asciiz "1........"
.asciiz "123456789"
.asciiz "......7.."
.asciiz "123456789"
.asciiz "....5...."
.asciiz "..3......"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "...4....."
.asciiz "123456789"
.asciiz ".......8."
.asciiz ".....6..."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz ".....6..."
.asciiz ".2......."
.asciiz ".......8."
.asciiz "......7.."
.asciiz "1........"
.asciiz "123456789"
.asciiz "1........"
.asciiz ".....6..."
.asciiz ".......8."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "........9"
.asciiz ".2......."
.asciiz "....5...."
.asciiz "......7.."
.asciiz "123456789"
.asciiz "........9"
.asciiz "123456789"
.asciiz "1........"
.asciiz "123456789"
.asciiz "123456789"
.asciiz ".......8."
.asciiz ".....6..."
.asciiz "123456789"
.asciiz "........9"
.asciiz "...4....."
.asciiz "..3......"
.asciiz "123456789"
.asciiz ".......8."
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "123456789"
.asciiz "1........"
.asciiz "123456789"
.asciiz "123456789"
.asciiz ".2......."
.asciiz ".....6..."
.asciiz "..3......"
.asciiz "........9"
.asciiz "..3......"
.asciiz "123456789"
.asciiz "....5...."
.asciiz "1........"
.asciiz "........9"
.asciiz "123456789"
.asciiz ".2......."
.asciiz "123456789"
.asciiz "123456789"
	
