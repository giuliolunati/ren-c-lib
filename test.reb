complex: import 'complex

write-stdout {
;; CUSTOMIZE code -block :"
>> probe make complex! [1 2] ; not customized
== }
probe make complex! [1 2]
write-stdout {>> do customize [probe make complex! [1 2]]
== }
do customize [probe make complex! [1 2]]

test: function [def] [probe make complex! def]
write-stdout {
;; CUSTOMIZE :function :
>> test: function [def] [probe make complex! def]
>> test [1 2] ; not customized
== }
test [1 2]
write-stdout {>> customize :test
>> test [1 2]
== }
customize :test
test [1 2]

write-stdout {
;; CUSTOMIZE self ;or other object :"
>> probe make complex! [1 2] ; not customized
== }
probe make complex! [1 2]
write-stdout {>> customize self
>> probe make complex! [1 2]
== }
customize self
probe make complex! [1 2]
