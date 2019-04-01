.PHONY:

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

#============================================

#both_setup_env:



#============================================

fpm_bash:
	$(call check_defined, INSTANCE)
#	it is a older variant, when fpm containers had auto-generated names with stable prefix
#	CONTAINER=$$(docker container ls | grep -o 'instance1_fpm_[^ ]*'); \
#	docker exec -it $$CONTAINER bash
	docker exec -it instance$(INSTANCE)_fpm bash


#============================================

open_brouser_all: open_browser_sites open_browser_pma

open_browser_sites:
	xdg-open http://localhost:8011
	xdg-open http://localhost:8012

open_browser_pma:
	xdg-open http://localhost:3331
	xdg-open http://localhost:3332

#============================================

both_docker_up:
	$(MAKE) instance_docker_up INSTANCE=1
	$(MAKE) instance_docker_up INSTANCE=2

both_docker_stop:
	$(MAKE) instance_docker_stop INSTANCE=1
	$(MAKE) instance_docker_stop INSTANCE=2

both_db_init:
	$(MAKE) instance_db_init INSTANCE=1
	$(MAKE) instance_db_init INSTANCE=2

both_db_composer_up:
	$(MAKE) instance_composer_up INSTANCE=1
#	we do not need to run composer update twice on same code :)
#	$(MAKE) instance_composer_up INSTANCE=2

both_db_composer_ins:
	$(MAKE) instance_composer_ins INSTANCE=1

both_setup_unv:
	$(MAKE) instance_setup_env INSTANCE=1
	$(MAKE) instance_setup_env INSTANCE=2

full_setup: both_setup_unv mount both_docker_up both_db_composer_ins both_db_init


#============================================


ENV_FILE=./instance$(INSTANCE)/.env
ifeq (1,$INSTANCE)
	OTHER_INSTANCE = 2
else
	OTHER_INSTANCE = 1
endif

instance_setup_env:
	$(call check_defined, INSTANCE)
#	echo $(ENV_FILE)
ifeq (,$(wildcard $(ENV_FILE)))
		echo 'file do not exist - create'
		cp instance1/.env.dist $(ENV_FILE)
		sed -i 's/NGINX_PORT=/NGINX_PORT=801$(INSTANCE)/g' $(ENV_FILE);
		sed -i 's/MYSQL_PORT=/MYSQL_PORT=332$(INSTANCE)/g' $(ENV_FILE);
		sed -i 's/MYSQL_PMA_PORT=/MYSQL_PMA_PORT=333$(INSTANCE)/g' $(ENV_FILE);
		sed -i 's/localhost:801/localhost:801$(OTHER_INSTANCE)/g' $(ENV_FILE);
		sed -i 's/MYSQL_DATABASE=/MYSQL_DATABASE=instance$(INSTANCE)/g' $(ENV_FILE);
		sed -i 's/MYSQL_ROOT_USER=/MYSQL_ROOT_USER=root/g' $(ENV_FILE);
		sed -i 's/MYSQL_ROOT_PASSWORD=/MYSQL_ROOT_PASSWORD=root/g' $(ENV_FILE);
else
		@echo 'file $(ENV_FILE) exist - skip'
endif

instance_docker_up:
	$(call check_defined, INSTANCE)
	cd instance$(INSTANCE); \
	docker-compose up -d

instance_docker_stop:
	$(call check_defined, INSTANCE)
	cd instance$(INSTANCE); \
	docker-compose stop

instance_composer_up:
	$(call check_defined, INSTANCE)
	docker exec instance$(INSTANCE)_fpm composer update

instance_composer_ins:
	$(call check_defined, INSTANCE)
	docker exec instance$(INSTANCE)_fpm composer install

instance_db_init: instance_db_create instance_db_update

instance_db_update:
	$(call check_defined, INSTANCE)
	docker exec instance$(INSTANCE)_fpm php bin/console doctrine:migrations:migrate

instance_db_create:
	$(call check_defined, INSTANCE)
	docker exec "instance$(INSTANCE)_fpm" php bin/console doctrine:database:create --if-not-exists

#============================================

mount:
	mkdir -p instance2/docker
	mkdir -p instance2/project
	sudo mount --bind instance1/docker instance2/docker/
	sudo mount --bind instance1/project instance2/project/

umount:
	sudo umount instance2/docker
	sudo umount instance2/project

#============================================
