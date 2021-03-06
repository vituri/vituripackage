% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{zipa_arquivos}
\alias{zipa_arquivos}
\title{Zipa arquivos.}
\usage{
zipa_arquivos(nome_pasta_zipada, arquivos, nivel_de_compressao = 9)
}
\arguments{
\item{nome_pasta_zipada}{Nome da pasta zipada.}

\item{arquivos}{Arquivos para zipar.}

\item{nivel_de_compressao}{Inteiro de 1 a 9: quanto maior, mais comprimido
porém leva mais tempo.}
}
\value{
Um arquivo .zip no local especificado.
}
\description{
Cria uma pasta zipada com arquivos selecionados.
}
