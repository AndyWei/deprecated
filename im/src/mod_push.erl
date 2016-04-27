%%%  Copyright (c) 2015 Joyy Inc. All rights reserved.


-module(mod_push).
-author('ping@joyyapp.com').

-behaviour(gen_mod).

-export([start/2,
	 stop/1,
	 send_notice/3]).

-include("ejabberd.hrl").
-include("jlib.hrl").

start(Host, Opts) ->
    ?INFO_MSG("Starting mod_push for host \"~s\"", [Host] ),
    ejabberd_hooks:add(offline_message_hook, Host, ?MODULE, send_notice, 10),
    ok.

stop(Host) ->
    ?INFO_MSG("Stopping mod_zeropush for host \"~s\"", [Host] ),
    ejabberd_hooks:delete(offline_message_hook, Host, ?MODULE, send_notice, 10),
    ok.

send_notice(From, To, Packet) ->
    Type = xml:get_tag_attr_s(list_to_binary("type"), Packet),
    Body = xml:get_path_s(Packet, [{elem, list_to_binary("body")}, cdata]),
    PostUrl = list_to_binary("http://api.winkrock.com:8000/v1/xmpp/push"),

    if (Type == <<"chat">>) and (Body /= <<"">>) ->
	      Sep = "&",
        Post = [
          "from=", From#jid.luser, Sep,
          "to=", To#jid.luser, Sep,
          "message=", url_encode(binary_to_list(Body))
        ],
        ?INFO_MSG("Sending post request to ~s with body \"~s\"", [PostUrl, Post]),
        httpc:request(post, {binary_to_list(PostUrl), [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
        ok;
      true ->
        ok
    end.


%%% The following url encoding code is from the yaws project and retains it's original license.
%%% https://github.com/klacke/yaws/blob/master/LICENSE
%%% Copyright (c) 2006, Claes Wikstrom, klacke@hyber.org
%%% All rights reserved.
url_encode([H|T]) when is_list(H) ->
    [url_encode(H) | url_encode(T)];
url_encode([H|T]) ->
    if
        H >= $a, $z >= H ->
            [H|url_encode(T)];
        H >= $A, $Z >= H ->
            [H|url_encode(T)];
        H >= $0, $9 >= H ->
            [H|url_encode(T)];
        H == $_; H == $.; H == $-; H == $/; H == $: -> % FIXME: more..
            [H|url_encode(T)];
        true ->
            case integer_to_hex(H) of
                [X, Y] ->
                    [$%, X, Y | url_encode(T)];
                [X] ->
                    [$%, $0, X | url_encode(T)]
            end
     end;

url_encode([]) ->
    [].

integer_to_hex(I) ->
    case catch erlang:integer_to_list(I, 16) of
        {'EXIT', _} -> old_integer_to_hex(I);
        Int         -> Int
    end.

old_integer_to_hex(I) when I < 10 ->
    integer_to_list(I);
old_integer_to_hex(I) when I < 16 ->
    [I-10+$A];
old_integer_to_hex(I) when I >= 16 ->
    N = trunc(I/16),
    old_integer_to_hex(N) ++ old_integer_to_hex(I rem 16).

