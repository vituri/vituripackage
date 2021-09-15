#' Tira espaço dos elementos de um vetor.
#'
#' @param x Um vetor de caracteres
#' @return O vetor sem espaços.
#' @examples
#' tira_espaco_do_nome("texto com espaco")
#' @export

tira_espaco_da_string = function(x) {
  y =
    x %>%
    gsub(pattern = " ", replacement = "", fixed = TRUE, x = .)

  return(y)
}

#' Tira ponto final da string
#'
#' @param x Um vetor de caracteres
#' @return O vetor sem pontos.
#' @examples
#' tira_ponto_da_string("texto.com.pontos")
#' @export

tira_ponto_da_string = function(x) {
  y =
    x %>%
    gsub(pattern = ".", replacement = "", fixed = TRUE, x = .)

  return(y)
}

#' Troca ponto final por espaço na string
#'
#' @param x Um vetor de caracteres
#' @return O vetor com espaço no lugar do ponto.
#' @examples
#' troca_ponto_por_espaco("texto.com.pontos")
#' @export

troca_ponto_por_espaco = function(x, x1) {
  y =
    x %>%
    gsub(pattern = ".", replacement = " ", fixed = TRUE, x = .)

  return(y)
}

#' Troca espaço por ponto final na string
#'
#' @param x Um vetor de caracteres
#' @return O vetor com ponto no lugar do espaço.
#' @examples
#' troca_espaco_por_ponto("texto com espaco")
#' @export
#'
troca_espaco_por_ponto = function(x, x1) {
  y =
    x %>%
    gsub(pattern = " ", replacement = ".", fixed = TRUE, x = .)

  return(y)
}

#' Substitui um vetor de caracteres por outro caracter
#'
#' @param x Um vetor de caracteres
#' @param de Os caracteres a serem substituídos. Pode ser um vetor.
#' @param para O caracter pelo qual serão trocados os valores do vetor 'de'.
#'
#' @examples
#' substitui_string(x = "a < b > c", de = c("<", ">"), para = "!")
#'
#' @export
#'
substitui_string = function(x, de, para = "") {
  y = x
  for (padrao in de) {
    y %<>% gsub(x = ., pattern = padrao, replacement = para, fixed = TRUE)
  }

  return(y)
}


getCurrentFileLocation <-  function()
{
  this_file <- commandArgs() %>%
    tibble::enframe(x = ., name = NULL) %>%
    tidyr::separate(col=value, into=c("key", "value"), sep="=", fill='right') %>%
    dplyr::filter(key == "--file") %>%
    dplyr::pull(value)
  if (length(this_file)==0)
  {
    this_file <- rstudioapi::getSourceEditorContext()$path
  }
  return(dirname(this_file))
}

#' Define o working directory como sendo a pasta onde se encontra salvo o script.
#'
#' @return Muda o wd.
#' @export

set_wd_aqui = function() {
  setwd(getCurrentFileLocation())
}

#' Envia emails usando o Outlook
#'
#' @description Monte emails usando o R e envie com o Outlook, com anexos, múltiplos contatos, etc. O
#'     email pronto será exibido e bastará apertar enviar. Só funciona usando R 3.6 (e não o 4).
#'
#' @param para Um vetor com emails (o que se escreve no 'para').
#' @param cc Um vetor com emails em cópia 'cc'.
#' @param bcc Um vetor com emails para cópia oculta.
#' @param assunto O assunto do email.
#' @param texto_email O texto do email (em html).
#' @param assinatura A assinatura do email (em html).
#' @param anexos Um vetor com o endereço dos anexos (o caminho pode estar relativo ao seu working directory).
#' @param exibir_email Se TRUE (padrão), exibe o email montado no Outlook (e voce envia apos checar).
#' @param enviar_email Se TRUE (o padrão é FALSE), envia o email logo após montar.
#' @param usar_utf8 Se FALSE (o padrão é TRUE), converte o assunto e o texto pro formato native.
#' @details O pacote RDCOMclient é meio chato de instalar. Se ao usar essa função
#' ele der erro de instalação, provavelmente terá que apagar um arquivo chamado
#' LOCK-não-sei-o-que (conforme escrito no erro que der) e tentar usar a função de novo. É preciso
#' instalar o Rtools35.
#'
#' @export

email_outlook = function(para = "", cc = "", bcc = "", assunto = "",
                         texto_email = "", assinatura = "", anexos = "",
                         exibir_email = TRUE, enviar_email = FALSE, usar_utf8 = TRUE, anexo_utf8 = TRUE){
  # carrega o pacote
  if (require(RDCOMClient) == FALSE) {
    if (version$major %in% '3') {
      devtools::install_github("dkyleward/RDCOMClient")
    } else {
      install.packages("RDCOMClient", repos = "http://www.omegahat.net/R")
    }
  }

  require(RDCOMClient)

  # Open Outlook
  Outlook <- COMCreate("Outlook.Application")

  # Create a new message
  Email = Outlook$CreateItem(0)

  # Set the recipient, subject, and body
  Email[["to"]] = para %>% paste(collapse = "; ")
  Email[["cc"]] = cc %>% paste(collapse = "; ")
  Email[["bcc"]] = bcc %>% paste(collapse = "; ")
  if (usar_utf8 == TRUE) {
    Email[["subject"]] = assunto %>% as.character()
  } else {
    Email[["subject"]] = assunto %>% as.character() %>% enc2native()
  }

  if (usar_utf8 == TRUE) {
    Email[["HTMLBody"]] = paste0(texto_email, "<br>", assinatura)
  } else {
    Email[["HTMLBody"]] = paste0(texto_email, "<br>", assinatura) %>% enc2native()
  }

  if (all(anexos != "")) {

    arquivos =
      anexos %>%
      normalizePath()

    if (anexo_utf8 == FALSE) {
      arquivos %<>% enc2native()
    }

    for (i in 1:length(arquivos)) {
      Email[["Attachments"]]$Add(arquivos[i])
    }
  }

  if (exibir_email == TRUE) {
    Email$Display()
  }

  if (enviar_email == TRUE) {
    Email$Send()
  }

}

#' Abre um arquivo usando o programa padrão do sistema operacional
#'
#' @description Abre arquivos no Linux e no Windows
#'
#' @param arquivo Uma string com o caminho do arquivo.
#' @details Se não funcionar, use o caminho completo (em vez do caminho relativo).
#'
#' @export

abre_arquivo = function(arquivo){
  if (sistema_operacional == "Linux") {
    system2(command = "xdg-open", args = arquivo)
  } else {
    shell.exec(arquivo)
  }
}

#' Cria conexão com uma base do SQLite.
#'
#' @description Cria uma tabela 'simbólica' do SQLite.
#'
#' @param local_database Uma string com o caminho do database.
#' @param nome_tabela Nome da tabela do SQLite para acessar.
#'
#' @return Uma conexão com o SQLite.
#'
#' @details Essa função retorna uma tabela
#'   na memória. Você poderá manipular ela como se estivesse de fato,
#'   usando os verbos do dplyr. Quando quiser realmente obter os dados
#'   após seus comandos, utilize 'collect()'.
#'
#' @export
#'
conecta_base_sqlite = function(local_database, nome_tabela) {

  # require(DBI); require(RSQLite)

  con = DBI::dbConnect(RSQLite::SQLite(),
                       dbname = local_database)

  return(tbl(con, nome_tabela))
}

#' Escreve dados no SQLite.
#'
#' @description Cria ou adiciona dados a uma tabela do SQLite
#'
#' @param dados_a_serem_salvos A tabela a ser salva no SQLite.
#' @param local_database Uma string com o caminho do database.
#' @param nome_tabela Nome da tabela do SQLite para acessar.
#' @param append Se os dados serão adicionados ao fim da tabela do SQLite (default: TRUE)
#' @param overwrite Se os dados sobrescreverão o que já existe no SQLite (default: FALSE)
#'
#' @details Use append = TRUE e overwrite = FALSE (padrão) para adicionar dados
#' a uma tabela já existente. Para sobrescrevê-la por completo, use
#' append = FALSE e overwrite = TRUE.
#'
#' @export
#'

escreve_numa_base_sqlite = function(dados_a_serem_salvos, local_database,
                                    nome_tabela, append = TRUE,
                                    overwrite = FALSE) {
  # require(DBI); require(RSQLite)

  con = DBI::dbConnect(RSQLite::SQLite(),
                       dbname = local_database)

  DBI::dbWriteTable(conn = con, name = nome_tabela,
                    value = dados_a_serem_salvos,
                    append = append, overwrite = overwrite)

}

#' Gera um calendário
#'
#' @description Gera uma tabela com dias, semanas, mês e ano, para usar
#' em algum left_join e assim agrupar seus dados por semana/mês/ano.
#'
#' @param data_inicial Data inicial do calendário.
#' @param data_final Data final do calendário.
#' @param dia_em_que_comeca_a_semana Iniciais do dia da semana em que
#' a semana começa no calendário. Valores possívels:
#' 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'.
#' @param semana Se TRUE, o calendário terá coluna 'Semana'.
#' @param mes Se TRUE, o calendário terá coluna 'Mês'.
#' @param ano Se TRUE, o calendário terá coluna 'Ano'.
#' @param dia_character Se TRUE, a coluna 'Dia' vem como character.
#'
#' @return Um dataframe.
#'
#' @export

gera_calendario =
  function(data_inicial = "2018-01-01",
           data_final = today(),
           dia_em_que_comeca_a_semana = "dom",
           semana = TRUE,
           mes = TRUE,
           ano = TRUE,
           dia_semana = FALSE,
           dia_character = FALSE) {

    data_inicial %<>% as_date()

    data_final %<>% as_date()

    temp = seq.Date(from = data_inicial - days(6),
                    to = data_inicial, by = 1)

    id = which(weekdays(x = temp, abbreviate = TRUE) == dia_em_que_comeca_a_semana, useNames = FALSE)

    dias_diferenca = (data_final - data_inicial) %>% as.numeric()

    qtd_semanas = (dias_diferenca %/% 7) + 1

    calendario = data.frame(Dia = seq.Date(from = temp[id],
                                           to = temp[id] + days(7*qtd_semanas - 1), by = 1))

    n = length(calendario$Dia)

    calendario$Semana = calendario$Dia[1]

    for (i in seq(1, n, by = 7)) {
      calendario$Semana[i:(i+6)] = calendario$Dia[i]
    }

    if (dia_semana == TRUE) {
      calendario$Dia_Semana = weekdays(calendario$Dia, abbreviate = TRUE)
    }

    if (semana == FALSE) {
      calendario %<>% select(-Semana)
    }

    if (mes == TRUE){
      calendario$Mês = calendario$Dia %>% format("%Y-%m-01")
    }

    if (ano == TRUE) {
      calendario$Ano = calendario$Dia %>% year() %>% as.character()
    }

    if (dia_character == TRUE){
      calendario$Dia %<>% as.character()
    }

    return(calendario)
  }

#' Zipa arquivos.
#'
#' @description Cria uma pasta zipada com arquivos selecionados.
#' @param nome_pasta_zipada Nome da pasta zipada.
#' @param arquivos Arquivos para zipar.
#' @param nivel_de_compressao Inteiro de 1 a 9: quanto maior, mais comprimido
#' porém leva mais tempo.
#'
#' @return Um arquivo .zip no local especificado.
#'
#' @export

zipa_arquivos = function(nome_pasta_zipada, arquivos, nivel_de_compressao = 9) {
  if (require(zip) == FALSE) {
    devtools::install_github("r-lib/zip")
  } else {
    require(zip)
  }

  zipr(zipfile = nome_pasta_zipada, files = arquivos, compression_level = nivel_de_compressao)

}

#' Escreve (dá append) numa base MariaDB
#'
#' @param conexao A conexão com o database.
#' @param nome_tabela Nome da tabela no database onde os dados serão salvos.
#' @param dados_a_serem_salvos A tabela com os dados a serem salvos no DB.
#' @param overwrite Se TRUE (padrão é FALSE), sobrescreve a tabela.
#' @param append Se TRUE (padrão), adiciona os dados ao fim da tabela existente, sem apagar nada.
#' @param encoding O encoding do csv que vai ser salvo pra depois subir pro mariadb. Se nulo,
#' tenta detectar sozinho de acordo com o sistema operacional. Às vezes é preciso forçar utf8
#' nele pra escrever direito no Linux. Não entendi o motivo ainda.
#' @export

escreve_numa_base_mariadb = function(conexao, nome_tabela, dados_a_serem_salvos,
                                     overwrite = FALSE, append = TRUE, encoding = NULL) {
  require(DBI)
  require(RMariaDB)
  if (Sys.info()["sysname"] %in% "Linux") {
    eol = "\n"
    fileEncoding = "latin1"
  } else {
    eol = "\r\n"
    fileEncoding = "UTF-8"
  }

  f = tempfile()
  dbFields = DBI::dbListFields(conexao, nome_tabela)
  if (append == TRUE) {
    for (dbField in dbFields) {
      if (!(dbField %in% colnames(dados_a_serem_salvos))) {
        dados_a_serem_salvos[[dbField]] = NA
      }
    }
  }

  dados_a_serem_salvos = dados_a_serem_salvos %>% select(all_of(dbFields))

  fileEncoding = if (is.null(encoding)) fileEncoding else encoding

  write.csv(dados_a_serem_salvos, file = f, row.names = F,
            na = "NULL", fileEncoding = fileEncoding, eol = eol)
  dbWriteTable(conexao, nome_tabela, f, append = append, overwrite = overwrite,
               eol = eol)
  unlink(f)
}

#' Escreve (dá append) numa base MariaDB
#'
#' @param conexao A conexão com o database.
#' @param nome_tabela Nome da tabela no database onde os dados serão salvos.
#' @param dados_a_serem_salvos A tabela com os dados a serem salvos no DB.
#' @param comando Comando para o INSERT, as opções são IGNORE ou REPLACE.
#' @export
#'
escreve_numa_base_mariadb2 = function(conexao, nome_tabela, dados_a_serem_salvos, comando = 'IGNORE')
{
  require(DBI)
  require(RMariaDB)

  # cria o endereço do arquivo temporário
  f = tempfile()

  # seleciona só os campos que existem na tabela de destino
  dbFields = DBI::dbListFields(conexao, nome_tabela)
  tabela = dados_a_serem_salvos %>% select(any_of(dbFields))

  # cria o arquivo temporário
  write.table(x = tabela, file = f, row.names = FALSE, col.names = FALSE,
              na = "NULL", fileEncoding = 'UTF-8', sep = '\t', append = FALSE, eol = '\n', quote = FALSE)

  # normaliza o endereço do arquivo
  arquivo = f %>% normalizePath(winslash = "/")

  colunas = colnames(tabela) %>% glue_collapse(sep = '`,`')

  # monta a query
  query = glue("
LOAD DATA LOCAL INFILE '{arquivo}'
{comando} INTO TABLE `{nome_tabela}`
CHARACTER SET 'utf8'
COLUMNS TERMINATED BY '\\t'
LINES TERMINATED BY '\\n'
(`{colunas}`)
")

  # executa a query
  DBI::dbExecute(conn = con, statement = query)

  # apaga o arquivo temporário
  unlink(f)
}

#' Procura a data mais recente em que ocorreu um dia da semana.
#'
#' @param data_a_considerar Data a partir da qual procurar uma semana pra trás.
#' @param dia_da_semana Abreviado. Valores: seg, ter, qua, qui, sex, sáb, dom.
#'
#' @return Um objeto date com a data mais recente que cai no dia da semana selecionado.
#'
#' @export

dia_recente_da_semana = function(data_a_considerar = lubridate::today(), dia_da_semana = "seg") {
  dias_pra_tras = data_a_considerar - lubridate::days(0:6)
  dia = dias_pra_tras[which(weekdays(dias_pra_tras, abbreviate = TRUE) == dia_da_semana)]

  return(dia)
}

#' Vetor com os nomes das colunas das tratativas no modelo antigo.
#'
#' @return Um vetor da hora.
#'
#' @export

nomes_colunas_tratativas = c(
  "Número", "Frota", "Placa", "Empresa", "Motorista", "Telefone", "Eventos",
  "Tipo de distração", "Tipo de alarme registrado", "Observações", "DataHora",
  "Tempo de processamento", "Duração do processamento", "Estado de processamento",
  "Usuario manipulador", "Método de processamento", "Descrição do processamento", "Velocidade",
  "Endereço", "Data Hora Brasil", "Dia", "Horário", "Mês", "...24", "Id Imagem",
  "Id Motorista", "Foto Selecionada?", "Tratado Manualmente?", "Id Cadastro Plataforma Argus",
  "Alarme Ajustado para relatorio", "Id Video N2", "Duplicados", "Contagem Duplicados",
  "...34", "Periodo baixado", "...36", "Longitude", "Latitude")


#' Lê a tratativa já com os nomes uniformes
#'
#' @param arquivo Local do arquivo: uma string com o endereço parcial ou completo.
#' @param use_openxlsx Decide se usa o openxlsx ou o readxl. O segundo dá pau com bad_alocc mas
#' às vezes mas é mais rápido. O openxlsx às vezes fica lendo pra sempre uma desgraça de excel e
#' só dá pra sair do R fechando pelo gerenciador de tarefas.
#'
#' @return data.frame chique.
#'
#' @export

le_tratativa_base_antiga = function(arquivo, use_openxlsx = FALSE, data_inicio, data_final) {

  glue('Lendo {basename(arquivo)}... {i} de {length(arquivos)} \n') %>% cat()

  if (use_openxlsx == TRUE) {
    temp = openxlsx::read.xlsx(xlsxFile = arquivo, startRow = 4, sheet = "B.TA",
                               skipEmptyRows = TRUE, skipEmptyCols = FALSE)
  } else {
    temp = readxl::read_excel(path = arquivo, skip = 3, sheet = "B.TA", guess_max = 200000)
  }

  n_col = min(38, ncol(temp))

  temp = temp[, 1:n_col]

  names(temp) = vituripackage::nomes_colunas_tratativas[1:n_col]

  temp$DataHora = lubridate::ymd_hms(temp$DataHora)

  temp %<>%
    select(Frota, Empresa, Eventos, `Tipo de distração`, `Tipo de alarme registrado`,
           Observações, DataHora, `Método de processamento`, `Descrição do processamento`,
           Velocidade, Endereço, Longitude, Latitude) %>%
    filter(DataHora >= data_inicio & DataHora < (data_final + days(1)))

  return(temp)
}

#' Pega a lista de tratativas e achata numa tabela só
#'
#' @param lista_de_tratativas Lista em que cada elemento é uma tabela.
#'
#' @return data.frame chique.
#'
#' @export

junta_tratativas_numa_tabela_so = function(lista_de_tratativas) {
  x =
    lista_de_tratativas %>%
    purrr::compact() %>%
    purrr::keep(.p = function(x) nrow(x) > 0) %>%
    lapply(function(tabela){
      x =
        tabela %>%
        mutate(across(!starts_with("DataHora"), ~ as.character(.)))

      x
    }) %>%
    bind_rows() %>%
    distinct()

  return(x)
}

#' Escreve direito os eventos de uma tratativa
#'
#' @param tabela Tabela com os eventos esculachados.
#'
#' @return data.frame chiquíssimo.
#'
#' @export

arruma_eventos_da_tratativa = function(tabela) {
  x = tabela

  x %<>%
    mutate(Eventos = case_when(
      Eventos %>% padrao_string('falso') ~ 'Falso Alarme',

      `Descrição do processamento` %>% padrao_string('falso') ~ 'Falso Alarme',

      Eventos %in% 'Sonolência' ~ case_when(
        `Tipo de alarme registrado` %>% padrao_string('n1') ~ 'Sonolência N1',
        `Tipo de alarme registrado` %>% padrao_string('n2') ~ 'Sonolência N2',
        TRUE ~ Eventos
      ),

      Eventos %in% 'Distração' ~ case_when(
        `Tipo de alarme registrado` %>% padrao_string('n1') ~ 'Olhando para baixo N1',
        `Tipo de alarme registrado` %>% padrao_string('n2') ~ 'Olhando para baixo N2',

        `Tipo de alarme registrado` %in% 'Olhar para o lado' &
          `Tipo de distração` %in% 'Olhar para o lado' ~ 'Olhar para o lado',

        `Tipo de alarme registrado` %in% 'Celular' &
          `Tipo de distração` %in% 'Celular' ~ 'Celular',

        `Tipo de alarme registrado` %in% 'Fumando' &
          `Tipo de distração` %in% 'Fumando' ~ 'Fumando',
        TRUE ~ Eventos
      ),

      `Tipo de alarme registrado` %>% padrao_string('bocejo') ~ 'Bocejo',
      TRUE ~ Eventos
    )
    )

  x %<>% arrange(lubridate::date(DataHora), Empresa)
  x$DataHora %<>% as.character()
  x$Latitude %<>% as.numeric()
  x$Longitude %<>% as.numeric()
  x$Velocidade %<>% as.numeric() %>% round(digits = 0) %>% as.character()

  return(x)
}

#' Lê várias tratativas e arquivos de processamento da base nova
#'
#' @param arquivos_eventos Local dos arquivos com as planilhas de eventos.
#' @param arquivos_processamentos Local dos arquivos com as planilhas de processamentos.
#'
#' @return data.frame chique.
#'
#' @export

le_tratativa_base_nova =
  function(arquivos_eventos, arquivos_processamentos = NULL) {

    # browser()
    temp1 =
      arquivos_eventos %>%
      lapply(function(arquivo) {
        temp = readxl::read_excel(path = arquivo, skip = 3)
      }) %>%
      bind_rows() %>%
      distinct()


    if (!is.null(arquivos_processamentos)) {
      temp2 =
        arquivos_processamentos %>%
        lapply(function(arquivo) {
          # browser()
          temp = readxl::read_excel(path = arquivo, skip = 2)
          temp$Velocidade %<>% as.numeric()
          names(temp)[5] = 'Organização controladora'
          temp %<>%
            rename(`Número de Placa` = `Número de placa de veículo`,
                   `Tipo de Alarme` = `Tipo de alarme`)

          return(temp)
        }) %>%
        bind_rows() %>%
        distinct()

      temp = left_join(temp1, temp2, by = c('Tipo de Alarme', 'Número de Placa', 'Hora de alarme'))
    } else {
      temp = temp1
    }

    return(temp)

  }

#' Checa se a string possui um certo padrão
#'
#' @param x String a ser testada.
#' @param pattern Padrão pra procurar na string
#' @param ignore.case Ignorar se é maiuscula ou minúscula (por padrão, TRUE).
#'
#' @return Vetor booleano. É só uma versão mais paipeável do grepl.
#'
#' @export

padrao_string = function(x, pattern, ignore.case = TRUE) {
  grepl(x = x, pattern = pattern, ignore.case = ignore.case)
}

#' Auto atualizador do futuro
#'
#' @return Retorna nada, só pega a versão mais recente do github e carrega.
#'
#' @export

carrega_pacote = function() {
  devtools::install_github("vituri/vituripackage", upgrade = 'never')
  library(vituripackage)
}

#' Checa se duas strings são iguais (sem dar pau com NA)
#' @param x String a ser testada.
#' @param y String a ser testada, de preferência do mesmo tamanho que x.
#'
#' @return Vetor booleano do memo tamanho que  x
#'
#' @export

compara_string = function(x, y) {
  1:length(x) %>%
    sapply(function(i) {
      identical(x[i], y[i])
    })
}

#' Checa se o try é um erro
#' @param x Objeto a ser testado
#'
#' @return TRUE se for erro, FALSE se não for.
#'
#' @export

eh_erro = function(x) {
  inherits(x, 'try-error')
}

#' Pega eventos da base de tratativas do mariadb e sobe pra base de Analytics correspondente
#' @param conexao_db_original Conexão com o db original de Analytics
#' @param conexao_db_tratativas Conexão com o db de tratativas
#' @param db_selecionado Nome do db selecionado (pra saber quais operações da tratativa
#' ele tem que pegar)
#' @param data_inicial Se NULL, usa '2018-01-01'
#' @param data_final Se NULL, usa o dia de ontem
#' @param usar_campo_empresa Se TRUE, busca o nome da empresa na coluna Nome_database da planilha Controle.
#' Se FALSE, busca pelo padrão do nome da operação.
#'
#' @return Retorna nada fi
#'
#' @export

consolida_base_tratativa_mariadb_nova = function(
  conexao_db_original, conexao_db_tratativas,
  db_selecionado, usar_campo_empresa = TRUE,
  data_inicial = NULL, data_final = NULL) {

  if (is.null(data_inicial)) {
    data_inicial = '2018-01-01'
  }

  if (is.null(data_final)) {
    data_final = today(tzone = 'Brazil/East') - days(1)
  }

  data_inicial %<>% as.character()

  data_final = data_final + days(1)
  data_final %<>% as.character()

  fx.controle =
    tbl(conexao_db_tratativas, 'Controle') %>%
    select(Nome_database, Operação)

  controle =
    fx.controle %>%
    collect()

  if (usar_campo_empresa == TRUE) {
    empresa_selecionada =
      controle %>%
      filter(Nome_database %>% padrao_string(db_selecionado)) %>%
      pull(Operação) %>%
      unique()
  } else {
    empresa_selecionada =
      controle %>%
      filter(Operação %>% padrao_string(db_selecionado)) %>%
      pull(Operação) %>%
      unique()
  }

  dados =
    tbl(conexao_db_tratativas, 'Eventos') %>%
    filter(Empresa %in% empresa_selecionada &
             `Horário registro` >= data_inicial &
             `Horário registro` < data_final) %>%
    collect()

  dados$`Horário de processamento` %<>% as.character()
  dados$`Horário registro` %<>% as.character()

  dados %<>%
    rename(DataHora = `Horário registro`,
           `Tipo de alarme registrado` = `Alarme registrado`)

  dados %<>%
    filter(!Eventos %in% 'Confirmação download')

  # con2 = argusinterno::conexao_mariadb(db_selecionado)

  glue('Baixando de {c(data_inicial, data_final) %>% unique() %>% paste(collapse = " a ")}') %>%
    cat()

  if (nrow(dados) > 0) {
    dados %>%
      escreve_numa_base_mariadb(conexao = conexao_db_original,
                                nome_tabela = 'Eventos', dados_a_serem_salvos = .)
    'Dados salvos!' %>% cat()
  } else {
    'Nenhum dado para salvar!' %>% cat()
  }

  return()
}

#' Transforma um vetor de string em um texto formatado pro sql
#' @param x Vetor de strings
#' @param data_para_mexer Data a partir da qual fazer a resumida
#'
#' @return Um vetor de tamanho 1
#'
#' @export

formata_string_sql = function(x) {
  paste0("('", x %>% paste0(collapse = "','"), "')")
}

#' Gera o num_eventos_frota do período correspondente em diante
#' @param con Conexão com o database
#' @param data_para_mexer Data a partir da qual fazer a resumida
#'
#' @return Nadinha
#'
#' @export

gera_num_eventos_frota = function(con, data_para_mexer = '2018-01-01') {

  data_para_mexer %<>% as.character()

  texto = glue("REPLACE
  INTO num_eventos_frota (`Empresa`, `Frota`, `Dia`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`)
  (SELECT `Empresa`, `Frota`, `Dia`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`
    FROM (SELECT `Empresa`, `Frota`, `Dia`, SUM(`Bocejo`) AS `Bocejo`, SUM(`Sonolência N1`) AS `Sonolência N1`, SUM(`Sonolência N2`) AS `Sonolência N2`, SUM(`Celular`) AS `Celular`, SUM(`Fumando`) AS `Fumando`, SUM(`Oclusão`) AS `Oclusão`, SUM(`Olhando para baixo N1`) AS `Olhando para baixo N1`, SUM(`Olhando para baixo N2`) AS `Olhando para baixo N2`
          FROM (SELECT `Empresa`, `Frota`, `Bocejo`, `Sonolência N1`, `Sonolência N2`, `Celular`, `Fumando`, `Oclusão`, `Olhando para baixo N1`, `Olhando para baixo N2`, DATE(`DataHora`) AS `Dia`
                FROM `Eventos`
                WHERE (`DataHora` >= '{data_para_mexer}')) `q01`
          GROUP BY `Empresa`, `Frota`, `Dia`) `q02`)")

  DBI::dbExecute(con, texto)
}

#' Data uma data, transforma em uma string no formato brasileiro. Tem opção de formatar pra mês/ano também.
#' @param x Vetor de datas.
#' @param tipo Semana ou mês. Se semana, fica dia/mês/ano. Se mês, fica mês/ano.
#'
#' @return Vetorzão da hora de characters.
#'
#' @export

converte_data_para_string = function(x, tipo = 'Semana') {
  y = x

  if (tipo %in% 'Semana') {
    y = x %>% format('%d/%m/%y')
  }

  if (tipo %in% 'Mês') {
    y = x %>% format('%m/%y')
  }

  return(y)
}

#' Insere uma tabela no db via uma query gigante
#' @param .data Dataframe para ser escrito no banco
#' @param con Conexão com o database
#' @param nome_tabela_db Nome da tabela no database
#' @param comando Comando que vai ser usado na inserção
#'
#' @return O tanto de linhas que foi alterado (conta o insert e o update)
#'
#' @export
#'
escreve_tabela_sql_geral = function(.data, con, nome_tabela_db, comando = 'REPLACE') {

  colunas_da_tabela = DBI::dbListFields(conn = con, name = nome_tabela_db)

  colunas_em_comum = dplyr::intersect(colunas_da_tabela, names(.data))

  colunas_excluidas = dplyr::setdiff(names(.data), colunas_da_tabela)

  if (length(colunas_excluidas) != 0) {
    warning(glue('Colunas {diferenca %>% paste(collapse = ', ')} foram descartadas...'))
  }

  temp =
    .data %>%
    select(any_of(colunas_em_comum)) %>%
    tidyr::unite(col = '.unite', sep = "','") %>%
    pull(.unite)

  if (length(temp) == 0) {
    warning('Nada para salvar')
    return(NULL)
  }

  values =
    glue("('{temp}')") %>%
    glue_collapse(sep = ',')

  nomes_colunas_formatado =
    colunas_em_comum %>%
    glue_collapse(sep = "`,`") %>%
    paste0("(`", ., "`)")

  query = glue("{comando} INTO `{nome_tabela_db}` {nomes_colunas_formatado} VALUES {values}")

  # query

  DBI::dbExecute(conn = con, statement = query)
}

#
# datatable(
#   data,
#   options = list(),
#   class = "display",
#   callback = JS("return table;"),
#   rownames,
#   colnames,
#   container,
#   caption = NULL,
#   filter = c("none", "bottom", "top"),
#   escape = TRUE,
#   style = "auto",
#   width = NULL,
#   height = NULL,
#   elementId = NULL,
#   fillContainer = getOption("DT.fillContainer", NULL),
#   autoHideNavigation = getOption("DT.autoHideNavigation", NULL),
#   selection = c("multiple", "single", "none"),
#   extensions = list(),
#   plugins = NULL,
#   editable = FALSE
# )
#
# datatable_simple = function(
#   data,
#   options = list(),
#   class = "display",
#   rownames = FALSE,
#   colnames,
#   container,
#   caption = NULL,
#   filter = c("none", "bottom", "top"),
#   escape = TRUE,
#   style = "auto",
#   width = NULL,
#   height = NULL,
#   elementId = NULL,
#   selection = c("multiple", "single", "none"),
#   extensions = list(),
#   editable = FALSE,
#   exibe_length_input = TRUE,
#   exibe_filtering = TRUE,
#   exibe_paginacao = TRUE,
#   exibe_botao = FALSE
#
#
# ) {
#
# }

#' A negação do %in%
#' @param a Vetor
#' @param b Vetor
#'
#' @return Logical
#'
#' @export

`%notin%` = function(a, b) {
  !a %in% b
}

waitress_infinite = function() {
  waitress <- waiter::Waitress$new(theme = "overlay-opacity", infinite = TRUE, hide_on_render = TRUE)

  return(waitress)
}
