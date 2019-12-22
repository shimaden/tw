include ../common.mk

SAMPLES = README.md sample.rb stream.rb update_profile_image.rb

install: $(SAMPLES)
	mkdir -m 2750 -p $(SAMPLESDIR)
	cp -p --update $(SAMPLES) $(SAMPLESDIR)
	chgrp -R staff $(SAMPLESDIR)
	chmod 0640 $(SAMPLESDIR)/*.md
	chmod 0640 $(SAMPLESDIR)/*.rb

.PHONY: uninstall
uninstall:
	cd $(SAMPLESDIR) && \rm -f *
	\rmdir $(SAMPLESDIR)

.PHONY: clean
clean:
	rm -f *~

