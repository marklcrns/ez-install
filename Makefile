INSTALL_DIR := /usr/local/bin
EZ_HOME := ~/.ez-install


install: $(INSTALL_DIR) $(INSTALL_DIR)/ez

$(INSTALL_DIR)/ez:
	sudo ln -sf $(EZ_HOME)/ez $@

${INSTALL_DIR}:
	sudo mkdir -p ${INSTALL_DIR}

.PHONY: test
test:
	docker-compose up --build --abort-on-container-exit

clean:
	sudo rm -f $(INSTALL_DIR)/ez $(INSTALL_DIR)/ez-gen
