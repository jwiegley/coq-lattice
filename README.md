# A Reflection-based Proof Tactic for Lattices in Coq

This code is largely based on work by Daniel W. H. James and Ralf Hinze from
their
paper
[A Reflection-based Proof Tactic for Lattices in Coq](http://www.cs.ox.ac.uk/ralf.hinze/publications/TFP09.pdf).
It also includes techniques presented by Arthur Azevedo de Amorim in his blog
entry
on
[Writing reflective tactics](http://poleiro.info/posts/2015-04-13-writing-reflective-tactics.html).

To use, provide type class instances for `LOSet` and its related type classes:
`Order`, `Reflexive`, `Transitive` and `Lattice`. You will then be able to use
the tactic `lattice` to solve goals expressed as inequalities that use the
`ord` operator (also `≤`) from the `Order` type class.

The code is straightforward enough that it can also serve as a template for
other decision procedures you might want to write, which are too complex for
Coq's own `Quote` library.
