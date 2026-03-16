# coq-lattice: A Reflection-based Proof Tactic for Lattices in Coq

I wanted an automatic tactic for solving lattice inequalities in Coq, and
couldn't find one that worked the way I needed. This library implements
Whitman's decision procedure as a certified, reflection-based tactic -- you
give it a goal like `a ⊓ b ≤ a ⊔ b` and it just solves it by computation.

The implementation is based on work by Daniel W. H. James and Ralf Hinze from
their paper [A Reflection-based Proof Tactic for Lattices in
Coq](http://www.cs.ox.ac.uk/ralf.hinze/publications/TFP09.pdf) (TFP09). I
also incorporated techniques from Arthur Azevedo de Amorim's blog post on
[Writing reflective
tactics](http://poleiro.info/posts/2015-04-13-writing-reflective-tactics.html),
which helped me get the reification right.

## How it works

The core idea is pretty simple: reify the lattice expression into an inductive
`Term` type, run a certified decision procedure (`leq`) that implements all six
cases of Whitman's algorithm via well-founded recursion, and then use
`vm_compute` to discharge the proof obligation. The decision procedure returns
a dependent pair `{ b : bool | b = true -> Leq s t }`, so when computation
succeeds, you get the proof for free.

## Usage

Provide type class instances for `LOSet` and its related type classes: `Order`,
`Reflexive`, `Transitive` and `Lattice`. Then use the `lattice` tactic to solve
goals expressed as inequalities using the `ord` operator (also `≤`) from the
`Order` type class:

```coq
Lemma median_inequality `{LOSet A} : forall x y z : A,
  (x ⊓ y) ⊔ (y ⊓ z) ⊔ (z ⊓ x) ≤ (x ⊔ y) ⊓ (y ⊔ z) ⊓ (z ⊔ x).
Proof. intros; lattice. Qed.
```

The code is straightforward enough that it can also serve as a template for
other decision procedures you might want to write, which are too complex for
Coq's own `Quote` library.

## Building

```bash
# Using Nix (recommended)
nix build
nix develop   # enter a shell with all dependencies

# Using make directly (requires Coq 8.18+)
make
```

## Compatibility

This library builds with Coq 8.18, 8.19, 8.20, and Rocq 9.0. The CI matrix
tests all four.

## License

BSD 3-Clause. See [LICENSE.md](LICENSE.md).
