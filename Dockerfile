FROM alpine:3.18 as builder

# Install dependencies, download, install UPX, and clean up in a single layer
RUN apk add --no-cache wget tar xz && \
    wget https://github.com/upx/upx/releases/download/v4.2.2/upx-4.2.2-amd64_linux.tar.xz && \
    tar -xf upx-4.2.2-amd64_linux.tar.xz && \
    cp upx-4.2.2-amd64_linux/upx /usr/local/bin/upx && \
    chmod +x /usr/local/bin/upx && \
    rm -rf upx-4.2.2-amd64_linux.tar.xz upx-4.2.2-amd64_linux

COPY target/x86_64-unknown-linux-musl/release/notify-mcp /notify-mcp
RUN chmod +x /notify-mcp

RUN upx --best --lzma /notify-mcp

# Create user and group files with a default UID/GID for appuser
# The actual runtime UID/GID will be set by 'docker run --user'
RUN echo "appuser:x:1000:1000::/home/appuser:/sbin/nologin" > /passwd_temp && \
    echo "appgroup:x:1000:" > /group_temp && \
    echo "root:x:0:0::/root:/sbin/nologin" >> /passwd_temp && \
    echo "root:x:0:" >> /group_temp

# Second stage: use scratch for a minimal image
FROM scratch

# Copy the binary from the builder stage
COPY --from=builder /notify-mcp /usr/local/bin/notify-mcp

# Copy the user/group files from the builder stage
COPY --from=builder /passwd_temp /etc/passwd
COPY --from=builder /group_temp /etc/group

# Default port (can be overridden with ENV, and will be read by the Rust application)
ENV PORT=3000

# Switch to the default non-root user. 'docker run --user' can override this.
USER appuser
# WORKDIR /home/appuser # WORKDIR may not be very useful in scratch

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/notify-mcp"]

# Expose the port (note this is just documentation, actual port needs to be mapped in docker run)
EXPOSE 3000
