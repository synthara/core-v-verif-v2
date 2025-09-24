// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Zineb EL KACIMI (zineb.el-kacimi@external.thalesgroup.com)


`ifndef __UVMA_CVXIF_RESP_ITEM_SV__
`define __UVMA_CVXIF_RESP_ITEM_SV__


/**
 * Object rebuilt from the CVXIF monitor
 */

class uvma_cvxif_resp_item_c extends uvm_sequence_item;

   rand x_compressed_resp_t   compressed_resp;
   rand x_issue_resp_t        issue_resp;
   rand x_result_t            result;

   rand logic                 issue_ready;
   rand logic                 compressed_ready;
   rand logic                 register_ready;
   rand logic                 result_valid;

   rand logic                 delay_resp;

   logic                      compressed_valid;
   logic                      issue_valid;

`uvm_object_utils_begin(uvma_cvxif_resp_item_c)
  `uvm_field_int(compressed_resp,   UVM_NOCOMPARE)
  `uvm_field_int(issue_resp,        UVM_NOCOMPARE)
  `uvm_field_int(result,            UVM_DEFAULT)

  `uvm_field_int(issue_ready,       UVM_NOCOMPARE)
  `uvm_field_int(compressed_ready,  UVM_NOCOMPARE)
  `uvm_field_int(register_ready,    UVM_NOCOMPARE)
  `uvm_field_int(result_valid,      UVM_DEFAULT)
  `uvm_field_int(delay_resp,        UVM_NOCOMPARE)

  `uvm_field_int(compressed_valid,  UVM_NOCOMPARE)
  `uvm_field_int(issue_valid,       UVM_NOCOMPARE)
`uvm_object_utils_end

   /**
    * Default constructor.
   */
   extern function new(string name="uvma_cvxif_resp_item");

virtual function bit do_compare(uvm_object rhs, uvm_comparer cmp);
  uvma_cvxif_resp_item_c R;
  bit match;

  if (!$cast(R, rhs)) return 1'b0;

  do_compare = super.do_compare(rhs, cmp);

  match = 1'b1;
  match &= cmp.compare_field("result.rd",   this.result.rd,   R.result.rd,   5);
  match &= cmp.compare_field("result.data", this.result.data, R.result.data, 32);

  foreach (this.result.we[i]) begin
    match &= cmp.compare_field($sformatf("result.we[%0d]", i),
                               this.result.we[i], R.result.we[i], 1);
    if (!match) return 1'b0; 
  end

  return do_compare;
endfunction

endclass : uvma_cvxif_resp_item_c

function uvma_cvxif_resp_item_c::new(string name="uvma_cvxif_resp_item");

   super.new(name);

endfunction : new


`endif //__UVMA_CVXIF_RESP_ITEM_SV__

