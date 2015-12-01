open Patch
open Document
open Storage
open Redis
open Assertions

let get_doc ctl =
  let opt = document_create ctl in
  (* Returns document's id *)
  match opt with Some d -> d | None -> "Failed to create doc"

(* Test whether connection was established *)
let ctlopt = storage_open "127.0.0.1" 6379
TEST = match ctlopt with Some _ -> true | None -> false

let ctl = match ctlopt with Some c -> c | None -> failwith "Failed to connect"


TEST_UNIT = print_string ((string_of_int (List.length (get_document_list ctl))) ^ "\n\n\n");
get_document_list ctl === []
let doc_id = get_doc ctl
TEST = set_document_text ctl doc_id "Lorem ipsum"
TEST_UNIT = get_document_text ctl doc_id === Some "Lorem ipsum"

(* Ensure get_document_list is updating *)
TEST = match get_document_list ctl with | [] -> false | h::t -> t = []

let doc_id2 = get_doc ctl
TEST = set_document_text ctl doc_id2 "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TEST_UNIT = get_document_text ctl doc_id2 === Some "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TEST_UNIT = get_document_text ctl doc_id === Some "Lorem ipsum"

(* For a deletion, the length of text represents the number of characters to be deleted *)
let deletion = [{op = Delete; pos = 0; text = "   "}]
TEST = add_document_patches ctl doc_id [deletion]

TEST_UNIT = match get_document_patches ctl doc_id 0 with
       | Some x ->
           (x:patch list) === [deletion]
       | None -> failwith ""


(* TODO: add test with adding two patch lists to document. Check order of patch lists *)


(* Setting document metadata *)
TEST = set_document_metadata ctl doc_id {title = "This is a title"}
let doc_metadata_option = get_document_metadata ctl doc_id
TEST = match doc_metadata_option with Some x -> true | None -> false
let doc_metadata = match doc_metadata_option with Some x -> x | None -> failwith "Get metadata failed"
let doc_title = doc_metadata.title
TEST_UNIT = doc_title === "This is a title"
(* Close connection *)
let _ = storage_close ctl

let _ = Pa_ounit_lib.Runtime.summarize ()
