(* LVM compatible bits and pieces *)

open Cmdliner
open Xenvm_common
open Lwt

let print_verbose vg lv =
  let read_write =
    let all =
      (if List.mem Lvm.Lv.Status.Read lv.Lvm.Lv.status
       then [ "read" ] else []) @
      (if List.mem Lvm.Lv.Status.Write lv.Lvm.Lv.status
       then [ "write" ] else []) in
    String.concat "/" all in
  let size = Int64.mul vg.Lvm.Vg.extent_size (Lvm.Lv.size_in_extents lv) in
  let lines = [
    "--- Logical volume ---";
    Printf.sprintf "LV Path                /dev/%s/%s" vg.Lvm.Vg.name lv.Lvm.Lv.name;
    Printf.sprintf "LV Name                %s" lv.Lvm.Lv.name;
    Printf.sprintf "VG Name                %s" vg.Lvm.Vg.name;
    Printf.sprintf "LV UUID                %s" (Lvm.Uuid.to_string lv.Lvm.Lv.id);
    Printf.sprintf "LV Write Access        %s" read_write;
    Printf.sprintf "LV Creation host, time unknown, unknown";
    Printf.sprintf "LV Status              %s" (if List.mem Lvm.Lv.Status.Visible lv.Lvm.Lv.status then "available" else "");
    Printf.sprintf "# open                 uknown";
    Printf.sprintf "LV Size                %Lds" size;
    Printf.sprintf "Current LE             %Ld" (Lvm.Lv.size_in_extents lv);
    Printf.sprintf "Segments               %d" (List.length lv.Lvm.Lv.segments);
    Printf.sprintf "Allocation:            inherit";
    Printf.sprintf "Read ahead sectors:    auto";
    (*
    - currently set to     256
    Block device           253:0
    *)
    "";
  ] in
  List.iter (fun line -> Printf.printf "  %s\n" line) lines

let print_colon vg lv =
  let sectors = Int64.mul vg.Lvm.Vg.extent_size (Lvm.Lv.size_in_extents lv) in
  let parts = [
    Printf.sprintf "/dev/%s/%s" vg.Lvm.Vg.name lv.Lvm.Lv.name;
    vg.Lvm.Vg.name;
    "?"; (* access *)
    "?"; (* volume status *)
    "?"; (* internal logical volume number *)
    "?"; (* open count *)
    Int64.to_string sectors; (* size in sectors *)
    "?"; (* current size in extents *)
    "?"; (* allocated extents *)
    "?"; (* allocation policy *)
    "?"; (* read ahead sectors *)
    "?"; (* major *)
    "?"; (* minor *)
  ] in
  Printf.printf "  %s\n" (String.concat ":" parts)

let lvdisplay copts colon (vg_name,lv_display_opt) =
  let open Xenvm_common in

  let t =
    get_vg_info_t copts vg_name >>= fun info ->
    set_uri copts info;
    Client.get () >>= fun vg ->
    let print = if colon then print_colon else print_verbose in
    let success = ref false in
    Lvm.Vg.LVs.iter (fun _ lv -> match lv_display_opt with
      | None ->
        print vg lv;
        success := true
      | Some lv' when lv.Lvm.Lv.name = lv' ->
        print vg lv;
        success := true
      | Some _ -> ()
    ) vg.Lvm.Vg.lvs;
    if not !success then failwith "Failed to find any matching logical volumes";
    Lwt.return () in
  Lwt_main.run t

let lvdisplay_cmd =
  let doc = "report information about logical volumes" in
  let man = [
    `S "DESCRIPTION";
    `P "lvdisplay produces formatted output about logical volumes";
  ] in
  let colon_arg =
    let doc = "Print in terse colon-separated form" in
    Arg.(value & flag & info ["colon";"c"] ~doc) in
  Term.(pure lvdisplay $ Xenvm_common.copts_t $ colon_arg $ Xenvm_common.name_arg),
  Term.info "lvdisplay" ~sdocs:"COMMON OPTIONS" ~doc ~man
