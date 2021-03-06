(**
 * Document Storage Module
 * 
 * Handles document storage using Redis.
 *)

open Patch
open Document
open Redis

type controller = {
    addr: string;
    port: int;
    conn: Redis_sync.Client.connection
  }

(**
 * Initialize the Redis connection at a given inet address and port. The
 * controller returned is used for any subsequent operation on this
 * connection. Returns None if no connection could be made
 *)
val storage_open : string -> int -> controller option

(**
 * Close the Redis connection.
 *)
val storage_close : controller -> unit

(**
 * Flush the storage database.
 *)
val storage_flush : controller -> bool -> unit

(**
 * Creates a document and returns its id, or None if creation failed.
 *)
val document_create : controller -> document_id option

(**
 * Returns a list of document ids in the storage.
 *)
val get_document_list : controller -> document_id list

(**
 * Retrieves document metadata given an id.
 *)
val get_document_metadata : controller -> document_id -> document_metadata option

(**
 * Retrieves document patches given an id.
 * Returns the last patches from a given index.
 *)
val get_document_patches : controller -> document_id -> int -> patch list option

(**
 * Returns the number of patches in a document.
 *)
val get_document_patch_count : controller -> document_id -> int option

(**
 * Retrieves document full text given an id.
 *)
val get_document_text : controller -> document_id -> document_text option

(**
 * Retrieves a document given an id.
 *)
val get_document : controller -> document_id -> document option

(**
 * Sets the metadata of a document.
 *)
val set_document_metadata : controller -> document_id -> document_metadata -> bool

(**
 * Adds patches to a document.
 *)
val add_document_patches : controller -> document_id -> patch list -> bool

(**
 * Sets the patches ofa  document.
 *)
val set_document_patches : controller -> document_id -> patch list -> bool

(**
 * Sets the full text of a document.
 *)
val set_document_text : controller -> document_id -> document_text -> bool

(**
 * Sets the contents of a document.
 *)
val set_document : controller -> document_id -> document -> bool
