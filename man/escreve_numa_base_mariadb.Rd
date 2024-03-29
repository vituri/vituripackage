% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sql_etc.R
\name{escreve_numa_base_mariadb}
\alias{escreve_numa_base_mariadb}
\title{Escreve (dá append) numa base MariaDB}
\usage{
escreve_numa_base_mariadb(
  conexao,
  nome_tabela,
  dados_a_serem_salvos,
  overwrite = FALSE,
  append = TRUE,
  encoding = NULL
)
}
\arguments{
\item{conexao}{A conexão com o database.}

\item{nome_tabela}{Nome da tabela no database onde os dados serão salvos.}

\item{dados_a_serem_salvos}{A tabela com os dados a serem salvos no DB.}

\item{overwrite}{Se TRUE (padrão é FALSE), sobrescreve a tabela.}

\item{append}{Se TRUE (padrão), adiciona os dados ao fim da tabela existente, sem apagar nada.}

\item{encoding}{O encoding do csv que vai ser salvo pra depois subir pro mariadb. Se nulo,
tenta detectar sozinho de acordo com o sistema operacional. Às vezes é preciso forçar utf8
nele pra escrever direito no Linux. Não entendi o motivo ainda.}
}
\description{
Escreve (dá append) numa base MariaDB
}
