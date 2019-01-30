REBOL [
	title: "SL4A interface"
	name: android
	type: module
	exports: [android]
	needs: [altjson]
	Purpose: "R3 interface for Scripting Layer 4 Android"
	System: "Rebol 3 Language Interpreter and Run-time Environment"
	author: ["Graham Chiu" "Giulio Lunati"]
	version: 0.0.1
	Date: [12-Mar-2017]
]
make-sl4a-error: func [
	message
] [
	; the 'do arms the error!
	do make error! [
		type: 'Access
		id: 'Protocol
		arg1: message
	]
]

awake-handler: func [event /local tcp-port] [
	;print ["=== Client event:" event/type]
	tcp-port: event/port
	switch/default event/type [
		error [
			;print "error event received"
			tcp-port/spec/port-state: 'error
			true
		]
		lookup [
			open tcp-port
			false
		]
		connect [
			;print "connected "
			write tcp-port tcp-port/locals
			tcp-port/spec/port-state: 'ready
			false
		]
		read [
			;print ["^\read:" length? tcp-port/data]
			tcp-port/spec/JSON: copy to string! tcp-port/data
			clear tcp-port/data
			true
		]
		wrote [
			;print "written, so read port"
			read tcp-port
			false
		]
		close [
			;print "closed on us!"
			tcp-port/spec/port-state: 'ready
			true
		]
	] [true]
]

sync-write: proc [sl4a-port [port!] JSON-string
	/local tcp-port
] [
	unless open? sl4a-port [
		open sl4a-port
	]
	tcp-port: sl4a-port/state/tcp-port
	tcp-port/awake: :awake-handler
	either tcp-port/spec/port-state = 'ready [
		write tcp-port to binary! JSON-string
	] [
		tcp-port/locals: copy JSON-string
	]
	unless port? wait [tcp-port sl4a-port/spec/timeout] [
		make-sl4a-error "SL4A timeout on tcp-port"
	]
]

sys/make-scheme [
	name: 'sl4a
	title: "SL4A Protocol"
	spec: make system/standard/port-spec-net [port-id: 4321 timeout: 60]

	actor: [
		open: func [
			sl4a-port [port!]
			/local tcp-port
		] [
			if sl4a-port/state [return sl4a-port]
			if blank? sl4a-port/spec/host [make-sl4a-error "Missing host address"]
			sl4a-port/state: context [
				tcp-port: _
			]
			sl4a-port/state/tcp-port: tcp-port: make port! [
				scheme: 'tcp
				host: sl4a-port/spec/host
				port-id: sl4a-port/spec/port-id
				timeout: sl4a-port/spec/timeout
				ref: rejoin [tcp:// host ":" port-id]
				port-state: 'init
				json: _
			]
			tcp-port/awake: _
			open tcp-port
			sl4a-port
		]
		open?: func [sl4a-port [port!]] [
			sl4a-port/state
		]
		write: func [sl4a-port [port!] data] [
			if not open? sl4a-port [
				open sl4a-port
			]
			sync-write sl4a-port data
			sl4a-port/state/tcp-port/spec/JSON
		]
		close: func [sl4a-port [port!]] [
			close sl4a-port/state/tcp-port
			sl4a-port/state: _
		]
	]
]
android: function [
  'method params
  <static>
  id (0)
	client (open join sl4a:// [
		get-env 'AP_HOST ":" get-env 'AP_PORT
	])
] [
	id: id + 1
	k: t: _
	m: :method
  if m = 'browse [
    m: 'view
    params: reduce [params _ _]
  ]
	i: id
	p: either/only block? params
		reduce params
		either/only params
			reduce [params]
			[]
	res: join to-json object [
		id: i
		method: m
		params: p
	] "^/"
	res: write client res
	load-json res
]

android _authenticate get-env 'AP_HANDSHAKE

; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
