## Changes about estrai_opcode.py ( Only relevant changes are about this script )

I created 7 dictionaries, one for each instruction format (R, I ,S, ecc.), and a separate dictionary which contain all these dictionaries (format_dicts)

Starting from line 214, this script is extracting from the json (instr_dict is "instr_dict.json" content) all the content and throw away all that is not variable fields, and create a dictionary named only_variable_fields that contains key = instruction's name and val = list of variable fields of that instruction

The script that starts from line 222 has been created in order to set the type of the instructions in the dictionary "only_variable_fields", in particular, based on the variable fields that every instruction own, it decide if this operation is R type, I type ecc.  Example: only_variable_fields = 'add': ['rd', 'rs1', 'rs2'], 'addi': ['rd', 'rs1', 'imm12'], ecc.     So this script will output instruction_format = 'add':R, 'addi':I, ecc.

The script that starts from line 248 is si creating the bitfield mapping. In this for, for each instruction, line 249 is deciding the instruction type (R, I, ecc.), and in line 250, based on the previous decision, I am extracting the varible fields of that particular type instruction. Then I am printing them in bitfield_mapping
Example of fmt_name and fmt_dict for 'add' and 'addi':
R
{'rd': '11:7', 'rs1': '19:15', 'rs2': '24:20'}
I
{'rd': '11:7', 'rs1': '19:15', 'imm12': '31:20'}


The script that starts from line 256 is filling the casez_dict which will contain all the stuff to be put in the case, in particular if the instruction name extracted from the file instr.sverilog (in opcode_dict) is equal to the one extracted from the json (in only_variable_fields)  (NB it has been used .lower because instruction were capital letter in inst.sverilog, while not in instr_dict.json). For the SB, S and UJ instruction I had to reconstruct the immediate, so I added an if for each of these cases.

Output file is /core-v-verif/lib/uvm_components/uvmc_rvfi_reference_model/uvmc_riscv_pcodes.sv" and seems correct and is also compiling with run_vcs (It says failed cause of the uvm_error in the default case, but it's ok because M and C instructions are missing and datas in the memory are also present)


## 15/04/2025 push

Added m instructions to the model using parse.py, added implementations for each i,m instruction in the file impl_dict.json. In line 288,289 in estrai_opcode.py implementations are added alongside variable fields. Added the reg_file to be accessed, the pc for instructions that require that and reg_mul to store all the result for the mul instructions ( 32 x 32 = 64)

## 23/04/2025 push

Added rv32_i instructions (pseudo instructions that were missing in i format) and csr instructions to the model. Added implementation for rv32_i instructions, but not for csr (I tried but was not sure about what I've done, I have a backup copy on my PC about csr implementation, we can discuss about it). I did not push run_vcs.py. I am trying to verify the correct behaviour of the code, but it's not running in the correct way yet ( I think some instruction implementation is not correct).

## 25/04/2025 push

Added csr implementation in the impl_dict.json (I used a new register file of 4096 refister not initialized). I inserted arg_lut.csv in the model, so I deleted field_specs dictionary which was containing the fields. I obtained the fields length by subtracting start and end bit ( ex rd -> 11:7  => 11-7 = 4 => bit [4:0] rd  (bit[start-end:0] rd)). I also changed the for loop in which the case is created: now every time there is a new instruction, all the variable fields of arg_lut are confronted with the ones of the instruction, and if there is a match, that particular variable fields is written down. So all the dictionaries with instruction type should not be useful anymore, but I decided to left them because I'm still using some of them to do the reconstruction of the immediate (SB, S and UJ instr.) in lines 321 - 326 of estrai_opcode.py. I also changed implementations of branches instructions, jal and jalr (jalr probably still not correct but better than before)


## 30/04/2025 push

Complete debug of all instructions in the program hello-world. I corrected instruction that use to work with the memory (load and store instructions), and I made some immediate extensions where it was needed because some operations were failing (such as the branches operations that add an immediate that needs to be extended (it's signed not unsigned), and also some addi and andi, ori). I resolved the store instructions problem, because all the registers outside the memory are on 32 bit, while every memory location is one byte, so for example when a store occours, 4 access in the memory are performed. Dual reason for load instructions. I verified all the instructions of program "Hello-world", verified with the file "uvm_test_top.env.rvfi_agent.trn.log". Unfortunately in this file  not all the instructions of the set are there ( example m-instructions are never used, and also other instructions such as lb, slt, slti, sra ecc.), but all the instructions that are in this file have been verified and they are all completely correct...   P.S. c-instructions still missing


## 02/05/2025 push

All the model is now able to decide if using a clock or not. In particularin the python script two blocks have been instantiated, one that permits the model to work with a clock and another without. You can decide to use the clock by setting the flag --set_clock, otherwise the model would work without the clock by default if no flag is inserted. N.B. without the clock the simulation stops right after wfi instruction has been detected ( I imposed this end otherwise without the clock the simulation is running forever because of the final jal), while with the clock, a lot of jal are executed before the program finishes to run, and I quite cannot explain this behaviour, but this is not compromising the correctness of the result of the simulation. In the sysverilog class there is a bit SENSE_CLK, that is not really used, but it's only for the user to know if he is in the clock mode or the no clock mode

## 07/05/2025

Model has been connected to the scoreboard as a substitute for the default reference model, in particular in my model (uvmc_riscv_opcodes) it has been created a rvfi_instr_seq_item to collect all the transactions from the model and a uvm_analysis port to send them to the scoreboard. In the uvme_cv32e20_env.sv class, all the instances about the default reference model have been commented, and new instances about the new reference model have been added, and by the end in the function connect_scoreboard, I commented the lines that were connecting the reference model for obvious reasons and I added the connection to my model. In the scoreboard I changed the check that was starting the comparison between dut and rm. I did this because rm begins to filling the transactions' queue before the core, if the check is done on the rm, when we're trying to pop the core's first element there will be nothing inside, and so it returns a null object error. ( With spike it was working because spike waits for the first core's transaction and then it's doing his own as a result )

## 09/05/2025 push

Program counter initial value has been added in the model by the parent class ( it's not hardwired anymore ), the function build_phase is taking care of it. Function step is inserted in the model, this function just waits for a transaction by the core, and only then the transaction by the reference model is happening. The decode opcode function has been inserted inside the step, that is then inserted inside a write_rvfi_instr, that provides the new transaction to the scoreboard by using the analysis_port. The python now has 3 run modes: one using the while (the reference model is generating the transactions instantly), with a clock ( the reference model is generating a new transaction after a clock cycle)    N.B These 2 ref models are generating new transactions faster than the core ( because some instructions could handle 2 or more clk cycles to be executed ). The last run mode has been setted as default and waits for a core transaction to produce a ref model transaction. In this way we can do again the check on the ref model in the scoreboard and not anymore on the core (because core was alwaays last to finish with 2 last modes, but now it's always ahead)

## 13/05/2025 push

C instructions added to the model, in particular all the instructions in the hello world test are now working and the test is arriving to the end succesfully (Test says failed because there is the wfi instruction that is not in the model but it's not a problem). It has been added in the python script a function that sorts the instructions in the case, in particular there was a problem for the c.jalr instruction, infact it was unable to access the case because it has the same encoding of the c.add instruction (c.jalr is a c.add that has rs2 = 0, but since c.add don't care about the value in rs2 and the check on the c.add is done before the check on the c.jalr, the instruction ,be it a c.jalr or a c.add, was always entering the c.add branch). The new function brings all the case_dict and it split the condition (name of the instruction), by the assign (implementation), and it's confronting it with the file opcode_priority.json. In this file youu can put, in order, the fìinstruction that you want to be put at the beginning of the case. In this way I was able to put the c.jalr before the c.add and not having the problem explained before.

## 14/05/2025 push

System_verilog class name changed from uvmc_riscv_opcodes to uvmc_rvfi_decoder_model. All updates have been done in all the files where it was mentioned ( in particular uvmt_cv32e20_model_test.sv ). Pythonmmodel has been changed name from estrai_opcode.py to decoder_autogen.py, and all italians words were deleted or replaced. All the scripts that were generating the instruction type (ex. R, I, UJ, ecc.) have been commented since they are no more useful ( all variable fields are extracted from arg_lut.csv with their bit-length ). Also all displays and print have been commented, except the last one in the python script, just because it leads to the path the SysVerilog class is created, and the $display in the constructor which is saying the time when the class is created.

## 16/05/2025 push

CV custom instructions added to the model in the folder extensions (just the first approximation, a more accurate debug is needed), and in particular, extension rv_addsub has been added to the model. Unfortunately the hello_world test program has not any of the custom instructions, so I'll not be able to verify with 100% accuracy the instruction's implementation in my model. 

## 21/05/2025 push

Extension rv_addsubls3 added to the model, same verification issues of previous added set ( hello_world test doesn't contain any custom instructions ), I had an issue with ls3 field of this instructions, so I decided finally to add the field ls3 in the arg_lut.csv file. Secondly, the first custom extensions set had an error inside its coding ( there was a mismatch with other instructions, but finally it was me that wrote incorrectly the coding inside the extension file ). I did another different push where I added the clip extensions, and also needed to add another argument in arg_lut.csv. 



## 22/05/2025 push

ReadmeTOT.md created in order to explain all the high level model



## 26/05/2025 push

Interface connection to the scoreboard has been fixed (before the model was not able to rely on the scoreboard on debugging the instructions), thus, decode_opcode function now returns the object interface, not anymore the pc, and also the function step had a bug inside it. Thanks to this fix, it's been possible to fix some problem regarding some m instructions, in particular rem, div and mulhsu. Another problem that has been fixed was the incompatibility of c instructions coding in the model, because in my model all the instructions were loaded from the memory 4 byte at times, but for c instructions only the last two are really needed. Because of this, in each c instruction case, here is an & between the instruction and 0x0000FFFF, in order to kill the first 16 bits. Three test programs have been tested and passed succesfully (hello-world, fibonacci and riscv_arithmetic_basic_test_0 ), and all the instructions inside them are correct also in the model. Few of the imc instructions need to be tested yet, in particular c_ebreak, c_nop, csrrc, csrrci, csrrsi, csrrwi, ebreak, ecall, fence, lb


## 28/05/2025 push

Added coprocessor and smart_LSU rtl to the model, the to include these devices to the verification model has to be given through the shell, by selecting -cop and -dmv respectively for the coprocessor and the smart_LSU ( It's better to add both of them or none, otherwise the model will not work because some filelist needed for the coproc are in the smart_LSU ), plus csr instructions have been fixed ( csr test instructions is not working, because some bits of some csr registers are hardcoded, and so I would need a bit mask for each register of the csr_register_file, but csr instructions implementation is correct in the model ). Next step is performing some tests with cv instr.


## 30/05/2025 push

Creation of new tests for some set of instructions. Instructions tested are cv_addsub instructions, and cv_addsublse instructions. A new test for both instructions has been created, in particular each test contains a hundred of cv instruction (addsub for the first test, addsubls3 for the second one), alongside some i, m or c instructions put randomly on the assembly code. To perform the new test, you have to add the program name to the run_vcs.py script. Both tests are terminated with 0 errors.

## 02/06/2025 push

Creation of model and test for clip instructions, test containing almost a thousand instructions alongside i, m and c instructions randomly. To perform the new test, you have to add the program name to the run_vcs.py script. Test terminated with 0 errors.

## 03/06/2025 push

Creation of model and test for cmpsimd instructions, test containing almost a thousand instructions alongside i, m and c instructions randomly. These new instructions could work either on .h or .b mode. Before the instruction arrive to the compiler, the only encoding recognisable by our compiler is the .h one. Now you are asking yourself: how could I handle the cv.cmpsimd.b instructions if the compiler doesn't recognise their encoding? Basically for our compiler, cv.cmpsimd.h and cv.cmpsimd.b instructions are literally the same instruction ( they have the same encoding ---> the cv.cmpsimd.h one, so if you are writing an assembly test file, you should put only these type of instructions, otherwise if you are putting a cv.cmpsimd instructions, its encoding will not be recognised by the compiler ). The rtl is able to differentiate the different instructions by checking the SIMD_DP csr register, so for the core, but also for the reference model, the instruction switch from .h to .b, or viceversa, only if there is a csrrwi inside the SIMD_DP register. Test has been performed with both .h and .b instructions ( some csrrwi was inserted ). Test has been passed with 0 errors.

## 04/06/2025 push

Creation of model and test for dotpsimd instructions, test containing almost a ten thousand instructions alongside i, m and c instructions randomly. Also this instructions can work in b or h mode, both have been implemented and tested correctly. mx format is still missing, because it is not clear wheter you need more operands than the ones contained in the variable fields. Test has been performed with both .h and .b instructions ( some csrrwi was inserted ). Test has been passed with 0 errors.

## 05/06/2025 push

Added the extension .mh to the dotpsimd instrcutions, the test has been updated, but pay attention: all mx instructions MUST be in couples, because 2 iterations needs to be performed in order to have the correct result ( the compiler apparently knows this ). So if you are trying to write different mx instructions inside a assembly file, you need to MANTAIN rd and op2, and you MUST CHANGE rs1. Only in this way the operation performed by the rtl ( and also the testbench ) will be correct. Test has been passed with 0 errors. Two new signals have been added in the autogen model: reg_result to save an inside of a register during a computation in the dotp instructions and iteration_mx, a bit that is used to recognise in ehich branch of the mx instructions we currently are.

## 06/06/2025 push

Creation of model and test for rv_genalu instructions, test containing almost a ten thousand instructions alongside i, m and c instructions randomly. Test has been performed with 0 errors. P.S. My model recognises cv.abs, cv.min, cv.minu, cv.max, cv.maxu with a '.w' on their end, that's because in another set there are some other instructions with the same name. Thus I used the .w on the end so that in the autogenertion of the case there is no incongruence in the instructions name ( because I'm autogenerating the instructions' implementation based on instruction name ).

## 10 and 11/06/2025 push

Creation of model and test for both rv_mac32 and rv_gensimd instructions, test containing 10k instructions for the second packet and a thousand for the first one ( just because rv_mac32 instr are basically 2 instructions, while gensimd are almost 100 ). The test has been created and passed with 0 errors for both instructions packets. 

## 12/06/2025 push

Creation of model and test for rv_mac168 instructions. The model has been implemented by adding a provisional register for mac.b instr to save part of the instruction computation in it. That's because the shift of ls3 bits was not computed correctly in one unique expression. The expression was splitted in two half, one that compute the add and mul, then the result is saved in this register, that is consequently used for the shift. I discussed with Francesco this problem, and that's probably because all computations in the rtl are performed on 16 bits for mac.b instr, while in the model, there could be the possibility that some variable, even if on 16 bit, is extended to perform a shift larger than 16 bits ( ls3 has 5 bits ---> max shift allowed is 32 ). The test has been passed with 0 errors for all the instructions. In another push I pushed the rv_168 mul instructions. Since the implementation is very similar, I used the same register I was using for mac168 operations to save an intermediate result. I renamed it to reg_mac_mul_prov since it's used by both instructions. Test has been passed with 0 errors also for this set of instructions. 

## 13/06/2025 push

Cv instruction have been all added to the model, but every time a test was finishing, it was going in a loop somewhere forever. The problem is that whenever spike is detecting a wfi instruction, it just sets up a bit ( halt bit ). The bit is not setted by a SystemVerilog file but, I suppose, in the C++ part DPI. Since thi bit was never setted to 1 in our model by anyone, the scoreboard couldn't know that the simulation was finished:

if (t_reference_model.halt || (sentinel_enable && (sentinel_value == t_reference_model.insn)))
    sim_finished = 1;

Here we can see that the bit sim_finished is setted to 1, only if the condition above is satisfied, but since noone was setting t_reference_model.halt  (spike does it, our model no), the simulation wasn't finishing and was going on a loop in the scoreboard. To get up to this problem I added a line in the wfi instruction that set the halt bit whenever detected. In this way the simulation was finishing for basic test. Concerning the added cv tests, they were still not finishing, because it's not enough writing wfi at the end of an assembly file to make the simulation stop. The correct way to write is j _test_pass, because there are more things the hardware have to do other than execute the wfi to make the simulation stop ( there are some stores and shift instructions ). I replaced the wfi with this j _test_pass, and now all tests are performed and finished as expected 


## 17/06/2025 push

Cv postinc load and store instructions have been added to the model. Implementation seems correct, but because I created the test, and I am bad at creating tests, sometimes there are mismatch in the result written in the memory. This happens because sometimes the address is too high and the memory isn't big enough to make an access to that address. Also sometimes there are probelms if there is the same register in two var fields. It happens also when they are all different but I don't get why ( maybe because the test has no sense at all, there are only load and store put randomly by chatgpt in the file ). Maybe a real test could be useful, also because the implementation after a lot of time debuggig seems correct to me