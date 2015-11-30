open Patch
open Document
open Storage
open Redis


let get_random_patch () =
let doc_size = Random.int 2000 in
let doc_text = get_random_text doc_size in

let num_edits = Random.int 50 in
let edits_array = Array.make num_edits [] in
for i = 0 to num_edits do
  let patch_op = if Random.int 1 = 0 then Insert else Delete in
  let patch_pos = Random.int doc_size in
  let size_patch_text = Random.int doc_size in
  let random_text = get_random_text size_patch_text in
  edits_array.(i) <- {op = patch_op; pos = patch_pos; text = random_text};
done
let edit_list = Array.to_list edits_array in
edit_list



let get_doc () =
  let opt = document_create ctl in
  (* Returns document's id *)
  match opt with Some d -> d | None -> "Failed to create doc"



 (* first test is to test whether connection was established *)
let ctlopt = storage_open "127.0.0.1" 6379
TEST = match ctlopt with Some _ -> true | None -> false

let ctl = match ctlopt with Some c -> c | None -> failwith "Failed to connect"

(* main functions to test are
set_document_text, add_document_patches, and their corresponding getters
*)



(*
let document_id_opt = document_create ctl
let doc_id = match document_id_opt with Some d -> d | None -> failwith "Failed to create doc"
 *)

let doc_id = get_doc ()

TEST = set_document_text ctl doc_id "Lorem ipsum"

TEST = get_document_text ctl doc_id = "Lorem ipsum"

(* Ensure get_document_list is updating *)
TEST = match get_document_list ctl with | [] -> false | h::t -> t = []

(* don't need to test patch operations here -- taht will be tested in test_patch.  so...
probably won't need to use get_random_patch *)


let new_doc_id_opt = document_create ctl2
let doc_id2 = match






(* Close connection *)
storage_close ctl;