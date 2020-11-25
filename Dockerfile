FROM docker.io/opendevorg/python-builder:3.7 as builder
# =============================================================================

COPY . /tmp/src
RUN ls -la /tmp/src
RUN assemble

FROM docker.io/opendevorg/python-base:3.7 as runner-base
# =============================================================================

COPY --from=builder /output/ /output
RUN ls -la /output/
RUN /output/install-from-bindep

# Prepare the /runner folder, seed the folder with demo data
ADD demo /runner

# In OpenShift, container will run as a random uid number and gid 0. Make sure things
# are writeable by the root group.
RUN for dir in \
      /home/runner \
      /home/runner/.ansible \
      /home/runner/.ansible/tmp \
      /runner \
      /home/runner \
      /runner/env \
      /runner/inventory \
      /runner/project \
      /runner/artifacts ; \
    do mkdir -m 0775 -p $dir ; chmod -R g+rwx $dir ; chgrp -R root $dir ; done && \
    for file in \
      /home/runner/.ansible/galaxy_token \
      /etc/passwd \
      /etc/group ; \
    do touch $file ; chmod g+rw $file ; chgrp root $file ; done

VOLUME /runner

WORKDIR /runner

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME=/home/runner

ADD utils/entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint

ENTRYPOINT ["entrypoint"]
CMD ["ansible-runner", "run", "/runner"]
