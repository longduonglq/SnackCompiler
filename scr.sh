java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p1.py < pre_pa4/p1_a.in > pre_pa4/p1_a.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p1.py < pre_pa4/p1_b.in > pre_pa4/p1_b.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p1.py < pre_pa4/p1_c.in > pre_pa4/p1_c.out

java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p2.py < pre_pa4/p2_a.in > pre_pa4/p2_a.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p2.py < pre_pa4/p2_b.in > pre_pa4/p2_b.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p2.py < pre_pa4/p2_c.in > pre_pa4/p2_c.out

java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p3.py < pre_pa4/p3_a.in > pre_pa4/p3_a.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p3.py < pre_pa4/p3_b.in > pre_pa4/p3_b.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p3.py < pre_pa4/p3_c.in > pre_pa4/p3_c.out

java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p4.py < pre_pa4/p4_a.in > pre_pa4/p4_a.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p4.py < pre_pa4/p4_b.in > pre_pa4/p4_b.out
java -cp "chocopy-ref.jar:target/assignment.jar" chocopy.ChocoPy --pass=rrr --run --profile pre_pa4/p4.py < pre_pa4/p4_c.in > pre_pa4/p4_c.out

sed -i  '1d;$d' pre_pa4/p1_a.out
sed -i  '1d;$d' pre_pa4/p1_b.out
sed -i  '1d;$d' pre_pa4/p1_c.out

sed -i  '1d;$d' pre_pa4/p2_a.out
sed -i  '1d;$d' pre_pa4/p2_b.out
sed -i  '1d;$d' pre_pa4/p2_c.out

sed -i  '1d;$d' pre_pa4/p3_a.out
sed -i  '1d;$d' pre_pa4/p3_b.out
sed -i  '1d;$d' pre_pa4/p3_c.out

sed -i  '1d;$d' pre_pa4/p4_a.out
sed -i  '1d;$d' pre_pa4/p4_b.out
sed -i  '1d;$d' pre_pa4/p4_c.out
