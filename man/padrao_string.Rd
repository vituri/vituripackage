% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/manipular_strings.R
\name{padrao_string}
\alias{padrao_string}
\title{Checa se a string possui um certo padrão}
\usage{
padrao_string(x, pattern, ignore.case = TRUE)
}
\arguments{
\item{x}{String a ser testada.}

\item{pattern}{Padrão pra procurar na string}

\item{ignore.case}{Ignorar se é maiuscula ou minúscula (por padrão, TRUE).}
}
\value{
Vetor booleano. É só uma versão mais paipeável do grepl.
}
\description{
Checa se a string possui um certo padrão
}
