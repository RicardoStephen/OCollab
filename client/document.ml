(*
 * Document Module Implementation
 *)

open Patch

type document_id = string

type document_metadata = {
    title: string
    (* Created, modified, views, etc. *)
  }

type document_text = string

type document = {
    id: document_id;
    metadata: document_metadata;
    patches: patch list;
    text: document_text
  }

let string_of_document doc =
  failwith "TODO now"

let document_of_string doc =
  failwith "TODO now"
