# Página além do total devolve lista vazia em vez de erro.
require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :empty_page
