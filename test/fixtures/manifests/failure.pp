# @summary A class to simulate failures
#
# @param fail
#   The ways to trigger a failure
class testing (
  Array[Enum['exec']] $fail = [],
) {
  $fail.each |$failure| {
    case $failure {
      'exec': {
        $command = "${$facts['kafo_test_tmpdir']}/failing-command"
        file { $command:
          ensure  => file,
          mode    => '0750',
          content => @(COMMAND),
            #!/bin/bash

            echo "This is stdout"
            echo "This is stderr" > /dev/stderr

            exit 100
          COMMAND
        }

        exec { 'failing-command':
          command     => $command,
          user        => $facts['identity']['user'],
          environment => [
            'KEY=value',
          ],
          require     => File[$command],
        }
      }
      default: {}
    }
  }
}
