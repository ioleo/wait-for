## wait-for

`wait-for.sh` is a fork of excellent `wait-for-it.sh` ([vishnubob/wait-for-it](https://github.com/vishnubob/wait-for-it)) which uses `curl` to query any HTTP endpoint.

## Usage

```
wait-for.sh [-h host] [-p port] [-e endpoint] [--secure] [-s] [-t timeout] [-- command args]
  -h HOST | --host=HOST                TCP host under test
  -p PORT | --port=PORT                TCP port under test
  -e ENDPOINT | --endpoint=ENDPOINT    Endpoint under test
  --secure                             Use HTTPS
  -s | --strict                        Only execute subcommand if the test succeeds
  -q | --quiet                         Don't output any status messages
  -t TIMEOUT | --timeout=TIMEOUT       Timeout in seconds, zero for no timeout
  -- COMMAND ARGS                      Execute command with args after the test finishes

  Example: wait-for.sh -h localhost -p 8080 -e health/check --secure -s -t 15 -- echo "Up and running!"
```

## Examples

For example, let's test to see if we can access port 80 on www.google.com, and if it is available, echo the message `google is up`.

```
$ ./wait-for.sh -h localhost -p 8080 -e health/check --secure -s -t 15 -- echo "Up and running!"
wait-for.sh: https://localhost:8080/health/check is available after 0 seconds
Up and running!
```

You can set your own timeout with the `-t` or `--timeout=` option.  Setting the timeout value to 0 will disable the timeout:

```
$ ./wait-for.sh -t 0 -h www.google.com -p 80 -- echo "google is up"
wait-for.sh: waiting for http://www.google.com:80/ without a timeout
wait-for.sh: http://www.google.com:80/ is available after 0 seconds
google is up
```

The subcommand will be executed regardless if the service is up or not.  If you wish to execute the subcommand only if the service is up, add the `--strict` argument. In this example, we will test port 81 on www.google.com which will fail:

```
$ ./wait-for.sh -h www.google.com -p 81 --timeout=1 --strict -- echo "google is up"
wait-for.sh: waiting 1 seconds for http://www.google.com:81/
wait-for.sh: timeout occurred after waiting 1 seconds for http://www.google.com:81/
wait-for.sh: strict mode, refusing to execute subprocess
```

If you don't want to execute a subcommand, leave off the `--` argument.  This way, you can test the exit condition of `wait-for-it.sh` in your own scripts, and determine how to proceed:

```
$ ./wait-for.sh -h www.google.com -p 80
wait-for.sh: waiting 15 seconds for http://www.google.com:80/
wait-for.sh: http://www.google.com:80/ is available after 0 seconds
$ echo $?
0
$ ./wait-for.sh -h www.google.com -p 81
wait-for.sh: waiting 15 seconds for http://www.google.com:81/
wait-for.sh: timeout occurred after waiting 15 seconds for http://www.google.com:81/
$ echo $?
124
```

