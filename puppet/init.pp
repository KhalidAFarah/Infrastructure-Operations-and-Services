class sensu-client {
  include sensu-client::install
  include sensu-client::configure
  include sensu-client::service
}
