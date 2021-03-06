(* XenVM LVM type thing *)

exception HostNotCreated

let _journal_name = "xenvm_journal"

external get_lv: name:string -> (Vg_wrapper.t * Lv_wrapper.t) = ""
(** [get_lv lv] returns all the information you need to be able to map
    the blocks of an LV: metadata for the VG (with an empty list of LVs)
    and metadata for the LV in question. *)

external get : unit -> Vg_wrapper.t = ""
external create : name:string -> size:int64 -> tags:string list -> unit = ""
external rename : oldname:string -> newname:string -> unit = ""
external remove : name:string -> unit = ""
external resize : name:string -> size:int64 -> unit = ""
external set_status : name:string -> readonly:bool -> unit = ""

external add_tag: name:string -> tag:string -> unit = ""
(** [add_tag name tag]: adds the tag to the named LV. If the tag already
    exists then this operation succeeds anyway. *)

external remove_tag: name:string -> tag:string -> unit = ""
(** [remove_tag name tag]: removes the tag from the named LV. If the LV
    hasn't got the tag then the operation succeeds anywya. *)

external flush : name:string -> unit = ""
(** [flush lv] processes all pending allocations for this LV, such that
    future calls to [get_lv] will return accurate metadata. *)

external shutdown : unit -> unit = ""

type queue = {
  lv: string;
  suspended: bool;
}

type host = {
  name: string;
  fromLVM: queue;
  toLVM: queue;
  freeExtents: int64;
}

module Host = struct

  external create: name:string -> unit = ""
  (** [create host] creates and initialises the metadata volumes
      for a host with name [host] *)

  external connect: name:string -> unit = ""
  (** [connect host] connects to existing metadata volumes and
      process them. *)

  external disconnect: name:string -> unit = ""
  (** [disconnect host] disconnects from metadata volumes and
      stops processing them. *)

  external destroy: name:string -> unit = ""
  (** [destroy host] removes the metadata volumes for a host with
      name [host] *)

  external all: unit -> host list = ""
end
