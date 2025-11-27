import os
import re
import json
import csv
import argparse
from utils.util import *
from utils.fmt import *

parser = argparse.ArgumentParser()
parser.add_argument("--set_clock", action = "store_true", help="Set the clock to the model")
parser.add_argument("--set_while", action="store_true", help="Set the while loop in the model")
parser.add_argument("--instantiate_cvxif", action="store_true", help="Instantiate the cvx interface")
args = parser.parse_args()

if args.set_clock:
    mode = "clock"
elif args.set_while:
    mode = "while"
else:
    mode = "step"

#Function to reorder the casez_dict based on the priority list
def reorder_casez_dict(casez_dict: dict, priority_path: str) -> dict:

    priority_map = {name: i for i, name in enumerate(priority_list)}

    num_entries = len(casez_dict) // 2
    pair_list = []
    for i in range(num_entries):
        cond = casez_dict[f"condition{i}"]
        assign = casez_dict[f"assign{i}"]
        pair_list.append((cond, assign))

    sorted_pairs = sorted(pair_list, key=lambda x: priority_map.get(x[0], 1000))

    new_casez_dict = {}
    for i, (cond, assign) in enumerate(sorted_pairs):
        new_casez_dict[f"condition{i}"] = cond
        new_casez_dict[f"assign{i}"] = assign

    return new_casez_dict

##################################################################################################################
#                                                                                                                #
#                                                   MAIN                                                         #
#                                                                                                                #
##################################################################################################################
script_dir = os.path.dirname(os.path.abspath(__file__))
config_json = os.path.join(script_dir, 'config', 'model_config.json')
instr_dict_json = os.path.join(script_dir, os.path.pardir, os.path.pardir, 'riscv-opcodes', 'instr_dict.json')
impl_dict_json = os.path.join(script_dir, 'config', 'instr_impl.json')
input_file = os.path.join(script_dir, os.path.pardir, os.path.pardir, 'lib', 'uvm_components', 'uvmc_rvfi_reference_model', 'uvmc_rvfi_decoder_pkg.sv')
arg_lut_file = os.path.join(script_dir, os.path.pardir, os.path.pardir, 'riscv-opcodes', 'arg_lut.csv')
opcode_priority = os.path.join(script_dir, 'config', "opcode_priority.json")


only_variable_fields = dict()  #Dictionary which will contain key = instruction's name and val = variable fields
opcode_dict = dict()           #Dictionary which will contain key = instruction's name and val = instruction's bit encoding
instruction_formats = dict()   #Dictionary which will contain key = instruction's name and val = instruction's type (R, I, S, ecc.)
bitfield_mapping = dict()      #Dictionary which will contain key = instruction's name and val = dictionary with the bitfield mapping for each variable fields
casez_dict = dict()            #Dictionary which will contain key = instruction's name and val = all the stuff to be put in the each case statement
implementations_dict = dict()  #Dictionary which will contain key = instruction's name and val = the implementation of the instruction

#Opening json to extract parameters to format the template
with open(config_json) as f:            
    config = json.load(f)

#Opening json to extract the opcode's variable fields
with open(instr_dict_json) as f1:         
    instr_dict = json.load(f1)

#Opening json to extract the implementation of each instruction
with open(impl_dict_json) as f2:
    impl_dict = json.load(f2)

#Opening csv to extract the opcode's bit encoding
with open(arg_lut_file) as f3:
    arg_lut = {row[0].strip('" '): (int(row[1]), int(row[2])) for row in csv.reader(f3)}

#Opening json to extract the opcode's priority
with open(opcode_priority) as f4:
    priority_list = json.load(f4)


#Extracting parameters from config.json to format the template
values = {                                       
    "class_name": config["name"],
    "parent": config["parent"],
    "main_class": config["main_class"].format(ilen=config["instr_width"], xlen=config["data_width"]),
    "instr_width": config["instr_width"],
    "path_name": config["path_name"],
}

csr_reg_init = "".join(
    f"{concat_indent(2)}csr_reg_file[CSR_{reg['name'].upper()}] = {hex2sv(reg['default_val'], config['data_width'])}; // {reg['name']}\n"
    for reg in config.get("csr_reg", [])
    if "default_val" in reg
)

#Extracting the field names and sizes from the field_specs dictionary
field_block = "".join(
    f"{f'bit [{start-end}:0]' if start != end else f'bit'} {field};\n{concat_indent(1)}"
    for field, (start, end) in arg_lut.items()
)

#Using regex to extract the instructions' names and bit encoding from the input file
if os.path.exists(input_file):
    
    with open(input_file, 'r') as file:
        lines = file.readlines()

    extract_opcode = re.compile(r'^\s*localparam\s+\[31:0\]\s+(\w+)\s*=\s*(\S+);')

    for line in lines:
        match = extract_opcode.match(line)
        if match:
            opcode_name = match.group(1)      
            bit_encoding = match.group(2)    
            opcode_dict[opcode_name] = bit_encoding  


#Extracting the variable fields for each instruction from the instr_dict.json
for instruction, data in instr_dict.items():                
    for i, (key, value) in enumerate(data.items()):
        if key == "variable_fields":
            only_variable_fields[instruction] = value    
                   
#Extracting the implementation for each instruction from the impl_dict.json
for instruction, impls in impl_dict.items():
    for i, (key, value) in enumerate(impls.items()):
        implementations_dict[instruction] = value

# Filling the casez_dict which will contain all the datas to be put in the case
for i, (key, val) in enumerate(opcode_dict.items()):
    casez_dict[f"condition{i}"] = f"{key}"
    casez_dict[f"assign{i}"]    = f'`uvm_info("{key}", \"Instruction {key} detected successfully\", {config["uvm_verbosity"]})\n'
    for j, (instr, fields) in enumerate(only_variable_fields.items()):
        if(key.lower() == instr.lower()):
            #fmt_name = instruction_formats[instr]
            for var_field, (start, end) in arg_lut.items():
                for single_field in fields:
                    if single_field == var_field:
                        indentation = concat_indent(4, "\t")
                        if start == end:
                            casez_dict[f"assign{i}"] += f"{indentation}{var_field} = instr[{start}];\n"
                        else:
                            casez_dict[f"assign{i}"] += f"{indentation}{var_field} = instr[{start}:{end}];\n"
            if instr.lower() in implementations_dict.keys():
                for line in implementations_dict[instr.lower()]:
                    indentation = concat_indent(line["indent"], "\t")
                    casez_dict[f"assign{i}"] += f"{indentation}{line['str'].replace('UVM_MEDIUM', config['uvm_verbosity'])}\n"

# Reordering the casez_dict based on the priority list
casez_dict = reorder_casez_dict(casez_dict, priority_list)

# This block manages the cases in which there is the clock or not
if mode == "clock":
    clock_code = clock_code
    while_code = ""  # Void: I'm not writing anything inside the constructor
    step_code = dummy_step_code.format(**config)
elif mode == "while":
    clock_code = ""    # Void: I'm not writing anything inside the run_phase
    while_code = while_code
    step_code = dummy_step_code.format(**config)
else:
    clock_code = ""    # Void: I'm not writing anything inside the run_phase
    while_code = ""    # Void: I'm not writing anything inside the run_phase
    step_code = step_code.format(**config)

additional_regs = "".join(
    f"{reg['type']} {reg['name'].format(**config)};\n{concat_indent(1)}"
    for reg in config.get("additional_regs", [])
)

def get_rvfi_block(cvx_if_present: bool) -> str:
    str_list = [rvfi_block.format(indent=concat_indent(2))]
    if cvx_if_present:
        str_list.append(cvx_block.format(indent=concat_indent(2), INDENT_ONE=INDENT_ONE))
    return "\n".join(str_list)


def get_seq_item_def(cvx_if_present: bool) -> str:
    str_list = [rvfi_seq_item_def.format(indent=concat_indent(1), ilen=config["instr_width"], xlen=config["data_width"])]
    if cvx_if_present:
        str_list.append(cvx_seq_item_def.format(indent=concat_indent(1)))
    return "\n".join(str_list)

def get_seq_item_assign(cvx_if_present: bool) -> str:
    str_list = [rvfi_seq_item_assign.format(indent=concat_indent(2), ilen=config["instr_width"], xlen=config["data_width"])]
    if cvx_if_present:
        str_list.append(cvx_seq_item_assign.format(indent=concat_indent(2)))
    return "\n".join(str_list)

# Formatting the template with the extracted parameters
casez_fmt = get_if_else_statement_fmt(length=len(opcode_dict)-1, case_format=True, always_comb=False)
    
casez_string = casez_fmt.format(
    indent=concat_indent(2),
    val="instr",
    default_assign= f"begin\n\n{concat_indent(4)}`uvm_error(\"UNKNOWN\", \"Unknown instruction detected\")\n{concat_indent(4)}incr = 4;\n\n{concat_indent(3)}end\n",
    **casez_dict,
)

file_content = template_content.format(csr_reg_init=csr_reg_init,
                                       casez_string=casez_string,**values, 
                                       fields_variables=field_block, 
                                       constructor_code=while_code, 
                                       run_phase_code=clock_code, 
                                       step_code=step_code, 
                                       rvfi_block=get_rvfi_block(args.instantiate_cvxif), 
                                       seq_item_def=get_seq_item_def(args.instantiate_cvxif), 
                                       seq_item_assign=get_seq_item_assign(args.instantiate_cvxif),
                                       additional_regs=additional_regs,
                                       uvm_verbosity=config["uvm_verbosity"]
                                       )



#Writing the formatted content to the sysverilog class
directory = os.path.join(script_dir, os.path.pardir, os.path.pardir, "lib", "uvm_components", "uvmc_rvfi_reference_model")

output_file = os.path.join(directory, config["name"] + ".sv")

with open(output_file, 'w') as file:
    file.write(file_content)

print(f"File content written to {output_file}")