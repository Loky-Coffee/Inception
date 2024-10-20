# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: aalatzas <aalatzas@student.42heilbronn.    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/10/20 19:17:09 by aalatzas          #+#    #+#              #
#    Updated: 2024/10/20 19:57:18 by aalatzas         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

YAML = srcs/docker-compose.yml

all: build run

build:
	docker compose -f $(YAML) build

run:
	docker compose -f $(YAML) up -d

stop:
	docker compose -f $(YAML) stop

down:
	docker compose -f $(YAML) down

re: down build up

logs:
	docker compose -f $(YAML) logs -f

clean:
	docker compose -f $(YAML) down --volumes --rmi all

status:
	docker compose -f $(YAML) ps

.PHONY: all build run stop down re logs clean status