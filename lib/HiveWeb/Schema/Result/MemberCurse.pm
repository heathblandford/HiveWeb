use utf8;
package HiveWeb::Schema::Result::MemberCurse;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/ UUIDColumns InflateColumn::DateTime /);
__PACKAGE__->table('member_curse');

__PACKAGE__->add_columns(
  'member_curse_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'member_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'curse_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
	'issued_at',
  {
    data_type     => 'timestamp with time zone',
    default_value => \'current_timestamp',
    is_nullable   => 0,
    original      => { default_value => \'now()' },
  },
	'lifted_at',
  {
    data_type     => 'timestamp with time zone',
    is_nullable   => 1,
  },
  'issuing_member_id',
  { data_type => 'uuid', is_foreign_key => 1, is_nullable => 0, size => 16 },
  'issuing_notes',
  { data_type => 'text', is_nullable => 1 },
);

__PACKAGE__->set_primary_key('member_curse_id');
__PACKAGE__->uuid_columns('member_curse_id');
__PACKAGE__->belongs_to(
  'member',
  'HiveWeb::Schema::Result::Member',
  { member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);
__PACKAGE__->belongs_to(
  'curse',
  'HiveWeb::Schema::Result::Curse',
  { curse_id => 'curse_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);
__PACKAGE__->belongs_to(
  'issuing_member',
  'HiveWeb::Schema::Result::Member',
  { issuing_member_id => 'member_id' },
  { is_deferrable => 0, on_delete => 'RESTRICT', on_update => 'RESTRICT' },
);

__PACKAGE__->meta->make_immutable;
1;
