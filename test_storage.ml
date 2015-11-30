open Patch
open Document
open Storage
open Redis

let get_doc ctl =
  let opt = document_create ctl in
  (* Returns document's id *)
  match opt with Some d -> d | None -> "Failed to create doc"

 (* first test is to test whether connection was established *)
let ctlopt = storage_open "127.0.0.1" 6379
TEST = match ctlopt with Some _ -> true | None -> false

let ctl = match ctlopt with Some c -> c | None -> failwith "Failed to connect"


TEST = get_document_list ctl = []

let doc_id = get_doc ctl
TEST = set_document_text ctl doc_id "Lorem ipsum"
TEST = get_document_text ctl doc_id = Some "Lorem ipsum"
(* Ensure get_document_list is updating *)
TEST = match get_document_list ctl with | [] -> false | h::t -> t = []

let doc_id2 = get_doc ctl
TEST = set_document_text ctl doc_id2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TEST = get_document_text ctl doc_id2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TEST = get_document_text ctl doc_id = "Lorem ipsum"


(* Add a patch to a document and ensure that the new document reflects that
   that patch. *)
let insertion = [{op  = Insert; pos = 0; text = "Insertion: "}]
TEST = add_document_patches ctl doc_id insertion
TEST = get_document_text ctl doc_id = "Insertion: Lorem ipsum"

(* For a deletion, the length of text represents the number of characters to be deleted *)
let deletion = [{op = Delete; pos = 0; text = "   "}]
TEST = add_document_patches ctl doc_id deletion

(*
TEST = match get_document_patches ctl doc_id -1 with
       | Some x -> x = [insertion; deletion] (* Correct order for insertion and deletion? *)
       | None -> false
*)

(* Close connection *)
storage_close ctl;
