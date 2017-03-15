do %httpd2.reb
server: open [
    scheme: 'httpd 8888 [
        probe request/action
        switch request/action [
            "GET /hello" [
                response/status: 200
                response/type: "text/plain"
                response/content: "Hello!"
            ]
        ]
    ]
]
