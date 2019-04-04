#!/bin/bash

FNAME=$1

cat <<EOF
\begin{figure}[H]
  \input{plot/UFS-alg/$FNAME}
  \caption{$FNAME}
\end{figure}
EOF
