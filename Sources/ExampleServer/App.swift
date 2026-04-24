import GeminiKit

private let indexPage = """
    # GeminiKit Test Server

    => /test/input              10 Input
    => /test/sensitive-input    11 Sensitive Input
    => /test/success            20 Success
    => /test/redirect           30 Temporary Redirect
    => /test/permanent-redirect 31 Permanent Redirect
    => /test/temporary-failure  40 Temporary Failure
    => /test/server-unavailable 41 Server Unavailable
    => /test/slow-down          44 Slow Down (60s)
    => /test/server-error       50 Server Error
    => /test/not-found          51 Not Found
    => /test/gone               52 Gone
    => /test/bad-request        59 Bad Request
    """

@main
struct ExampleServer: Server {
    let config = Config(
        certificatePath: Bundle.module.url(forResource: "cert", withExtension: "pem")!,
        privateKeyPath: Bundle.module.url(forResource: "key", withExtension: "pem")!
    )

    var body: some Route {
        Path("/") { Success(indexPage) }

        Path("/test/input") {
            Input("What is your query?") { query in
                Success("You said: \(query)")
            }
        }
        Path("/test/sensitive-input") {
            SensitiveInput("Enter a secret:") { _ in
                Success("Secret received.")
            }
        }
        Path("/test/success") {
            Success("# 20 Success\nThis is a successful response.")
        }
        Path("/test/redirect") {
            Redirect(to: "/test/redirect/destination")
        }
        Path("/test/redirect/destination") {
            Success("You were temporarily redirected here.")
        }
        Path("/test/permanent-redirect") {
            PermanentRedirect(to: "/test/permanent-redirect/destination")
        }
        Path("/test/permanent-redirect/destination") {
            Success("You were permanently redirected here.")
        }
        Path("/test/temporary-failure") {
            Failure()
        }
        Path("/test/server-unavailable") {
            ServerUnavailable()
        }
        Path("/test/slow-down") {
            SlowDown(seconds: 60)
        }
        Path("/test/server-error") {
            ServerError()
        }
        Path("/test/not-found") {
            NotFound()
        }
        Path("/test/gone") {
            Gone()
        }
        Path("/test/bad-request") {
            BadRequest()
        }
    }
}
