// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Zineb EL KACIMI (zineb.el-kacimi@external.thalesgroup.com)


`ifndef __UVMA_CVXIF_REQ_ITEM_SV__
`define __UVMA_CVXIF_REQ_ITEM_SV__


/**
 * Object rebuilt from the CVXIF monitor
 */
class uvma_cvxif_req_item_c extends uvm_sequence_item;

   rand x_issue_req_t       issue_req;
   rand x_compressed_req_t  compressed_req;
   rand x_register_t        register;
   rand x_commit_t          commit_req;

   rand logic               issue_valid;
   rand logic               compressed_valid;
   rand logic               register_valid;
   rand logic               commit_valid;
   rand logic               result_ready;

   `uvm_object_utils_begin(uvma_cvxif_req_item_c)
      `uvm_field_int(issue_req, UVM_DEFAULT)
      `uvm_field_int(compressed_req, UVM_NOCOMPARE)
      `uvm_field_int(register, UVM_DEFAULT)
      `uvm_field_int(commit_req, UVM_NOCOMPARE)

      `uvm_field_int(issue_valid, UVM_DEFAULT)
      `uvm_field_int(compressed_valid, UVM_NOCOMPARE)
      `uvm_field_int(register_valid, UVM_NOCOMPARE)
      `uvm_field_int(commit_valid, UVM_DEFAULT)
      `uvm_field_int(result_ready, UVM_NOCOMPARE)
   `uvm_object_utils_end

   /**
    * Default constructor.
   */
   extern function new(string name="uvma_cvxif_req_item");

endclass : uvma_cvxif_req_item_c

function uvma_cvxif_req_item_c::new(string name="uvma_cvxif_req_item");

   super.new(name);

endfunction : new


`endif // __UVMA_CVXIF_REQ_ITEM_SV__
