open Base
open Printf

type operator =
    | Add
    | Neg
    | Mul
    | Div
    | LT
    | GT
    | EQ
    | NEQ
    | And
    | Or
    | Mod
    | Head
    | Tail
    | Not

type value =
    | Number of float
    | Boolean of bool
    | Tuple of value list
    | ValList of value list
    | Lambda of lambda
    | Thunk of {thunk_fn: lambda; thunk_args: value; thunk_fn_name: string}

and pattern =
    | SinglePat of string
    | NumberPat of float
    | TuplePat of pattern list
    | ListPat of list_pattern
    | WildcardPat

and list_pattern =
    | FullPat of pattern list
    | HeadTailPat of (pattern list) * pattern

and state = (string, value, String.comparator_witness) Map.t

and lambda = {lambda_expr: expr; lambda_args: pattern; enclosed_state: state}
and lambda_call = {callee: string; call_args: expr}
and if_expr = {cond: expr; then_expr: expr; else_expr: expr}

and expr =
    | Atomic of value
    | Ident of string
    | Binary of {lhs: expr; op: operator; rhs: expr}
    | Prefix of {op: operator; rhs: expr}
    | Let of {assignee: pattern; assigned_expr: expr}
    | LambdaDef of {lambda_def_expr: expr; lambda_def_args: pattern}
    | LambdaCall of lambda_call
    | IfExpr of  if_expr
    | TupleExpr of expr list
    | BlockExpr of expr list
    | MatchExpr of {match_val: expr; match_arms: (pattern * expr * expr option) list}
    | ListExpr of (expr list) * (expr option)

let rec string_of_val = function
    | Number n -> Float.to_string n
    | Boolean b -> Bool.to_string b
    | Tuple ls -> "(" ^ String.concat ~sep:", " (List.map ~f:string_of_val ls) ^ ")"
    | ValList ls -> "[" ^ String.concat ~sep:", " (List.map ~f:string_of_val ls) ^ "]"
    | Lambda _ -> "Lambda"
    | Thunk _ -> "Thunk"

let rec string_of_expr = function
    | Atomic v -> string_of_val v
    | Ident s -> s
    | Prefix (_ as p) -> sprintf "{rhs: %s}" (string_of_expr p.rhs)
    | Binary (_ as b) -> sprintf "{lhs: %s, rhs: %s}" (string_of_expr b.lhs) (string_of_expr b.rhs)
    | Let (_ as l) -> sprintf "Let %s = %s" (string_of_pat l.assignee) (string_of_expr l.assigned_expr)
    | LambdaDef _ -> "Lambda"
    | LambdaCall call -> sprintf "{Call: %s, args: %s}" call.callee (string_of_expr call.call_args)
    | TupleExpr ls -> sprintf "(%s)" (String.concat ~sep:", " (List.map ~f:string_of_expr ls))
    | ListExpr (ls, tail) -> 
        sprintf "[%s|%s]"
        (String.concat ~sep:", " (List.map ~f:string_of_expr ls))
        (if Option.is_none tail then "None" else "Tail")
    | IfExpr _ -> "IfExpr"
    | BlockExpr ls -> sprintf "{\n\t%s\n}" (String.concat ~sep:"\n\t" (List.map ~f:string_of_expr ls))
    | MatchExpr _ -> "MatchExpr"

and string_of_list_pat = function
    | FullPat ls -> "[" ^ (String.concat ~sep:", " (List.map ~f:string_of_pat ls)) ^ "]"
    | HeadTailPat (_hd, _tl) -> assert false (* TODO *)

and string_of_pat = function
    | SinglePat s -> s
    | ListPat lp -> (string_of_list_pat lp)
    | NumberPat f -> Float.to_string f
    | TuplePat ls -> sprintf "(%s)" (String.concat ~sep:", " (List.map ~f:string_of_pat ls))
    | WildcardPat -> "_"
