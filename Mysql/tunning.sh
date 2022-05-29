##Caminho##
#cd /etc/my.cnf.d
#vim mysql-server.cnf

#Um arquivo por tabela
innodb_file_per_table = 1

#Utilizar 75% de memoria da maquina
innodb_buffer_pool_size = 3G

#<=1GB - 1 >1GB <=16GB - 8 >16GB - 2G
innodb_buffer_pool_instances = 4

innodb_flush_method = O_DIRECT

#Quando maior o arquivo, menos I/O utilizado
innodb_log_file_size = 256M

#Numero maximo de conexoes
max_connections = 300

#Os logs sao gravados apos cada transação conmfirmada
innodb_flush_log_at_trx_commit = 2
