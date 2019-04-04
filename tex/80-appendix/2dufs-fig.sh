#!/bin/bash

FNAME=$1
LATEX=$(echo $FNAME | sed 'sm_m\\\_m')

cat <<EOF
\begin{figure}[H]
  \input{plot/2D-UFS/$FNAME}
  \caption{$LATEX}
\end{figure}
EOF
