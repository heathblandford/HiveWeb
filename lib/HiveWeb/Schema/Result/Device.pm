use utf8;
package HiveWeb::Schema::Result::Device;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components('InflateColumn::DateTime');

__PACKAGE__->table('device');

__PACKAGE__->add_columns(
  'device_id',
  { data_type => 'uuid', is_nullable => 0, size => 16 },
  'key',
  { data_type => 'bytea', is_nullable => 0 },
  'name',
  { data_type => 'varchar', is_nullable => 0, size => 64 },
  'nonce',
  { data_type => 'bytea', is_nullable => 1 },
	'min_version',
	{ data_type => 'integer', is_nullable => 0, default_value => '1', },
	'max_version',
	{ data_type => 'integer', is_nullable => 0, default_value => '1', },
	);

__PACKAGE__->set_primary_key('device_id');

__PACKAGE__->has_many(
	'device_items',
	'HiveWeb::Schema::Result::DeviceItem',
	{ 'foreign.device_id' => 'self.device_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many(
	'vend_logs',
	'HiveWeb::Schema::Result::VendLog',
	{ 'foreign.device_id' => 'self.device_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many(
	'bulbs',
	'HiveWeb::Schema::Result::LampBulb',
	{ 'foreign.device_id' => 'self.device_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->many_to_many('items', 'device_items', 'item');
__PACKAGE__->meta->make_immutable;
1;
