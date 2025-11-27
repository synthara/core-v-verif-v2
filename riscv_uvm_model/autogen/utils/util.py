import math

# Global variables to make an indentation when needed
INDENT_ONE = "    "

def ceil_log2(x):
    if type(x) == str:
        x = int(x)
    return math.ceil(math.log2(x))

def hex2sv(hex_string: str, sv_size: int = 32) -> str:
    """
    Converts a hexadecimal string to SystemVerilog format with specified size.

    Args:
        hex_string (str): The hexadecimal string to convert (e.g., "0x1A3F").
        sv_size (int, optional): The size in bits for the SystemVerilog representation. Defaults to 32.

    Returns:

        str: The SystemVerilog formatted string (e.g., "32'h1A3F").
    """
    # Remove the '0x' prefix if present
    if hex_string.startswith("0x") or hex_string.startswith("0X"):
        hex_string = hex_string[2:]

    return f"{sv_size}'h{hex_string}"

def concat_indent(times: int, base_indent: str=INDENT_ONE) -> str:
    """
    Concatenates the base indentation string a specified number of times.

    Args:
        base_indent (str): The base indentation string.
        times (int): The number of times to concatenate the base indentation.

    Returns:
        str: The concatenated indentation string.
    """
    return base_indent * times

def get_if_else_statement_fmt(length: int, always_comb: bool = True, implicit_final_condition: bool = True, case_format: bool = False, unique: bool = False, default_assign: bool = True) -> str:
    """
    Generates a formatted string for an if-else or case statement in SystemVerilog.
    Args:
        length (int): The number of conditions to generate.
        always_comb (bool, optional): If True, wraps the statement in an always_comb block. Defaults to True.
        implicit_final_condition (bool, optional): If True, the final else condition is implicit. Defaults to True.  
        case_format (bool, optional): If True, generates a case statement instead of if-else. Defaults to False.
    Returns:
        str: A formatted string representing the if-else or case statement.
    """
    
    if always_comb:
        out_fmt = "always_comb begin\n"
    else:
        out_fmt = "\n"
        
    if case_format is True:
        
        if unique:
            out_fmt += "{indent}unique case ({val})\n"
        else:
            out_fmt += "{indent}casez ({val})\n\n"
        for i in range(length+1):
            out_fmt += f"{{indent}}{concat_indent(1)}{{condition{i}}} : begin\n\n{{indent}}{{indent}}{{assign{i}}}\n{{indent}}{INDENT_ONE}end\n\n"

        if default_assign is True:
            out_fmt += f"{{indent}}{concat_indent(1)}default: {{default_assign}}\n\n"    
        
        out_fmt += "{indent}endcase\n"
    else:
        for i in range(length):
            if i == 0:
                out_fmt += f"{{indent}}\tif ({{condition{i}}}) begin\n"
            elif i == length-1 and implicit_final_condition is True:
                out_fmt += "{indent}\tend else begin\n"
            else:
                out_fmt += f"{{indent}}\tend else if ({{condition{i}}}) begin\n"
                
            # out_fmt += f"{{indent}}\t\t{{lhs}} = {{rhs{i}}};\n"
            out_fmt += f"{{assign{i}}}"

        out_fmt += "{indent}\tend\n"
    
    if always_comb:
        out_fmt += "\tend\n"
    
    return out_fmt