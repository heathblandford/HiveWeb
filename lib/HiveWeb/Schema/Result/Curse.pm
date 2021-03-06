use utf8;
package HiveWeb::Schema::Result::Curse;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'HiveWeb::DBIx::Class::Core';

use Text::Markdown 'markdown';

__PACKAGE__->load_components(qw{ UUIDColumns InflateColumn::DateTime });
__PACKAGE__->table("curse");

__PACKAGE__->add_columns(
  "curse_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "priority",
  {
    data_type     => 'integer',
    default_value => \'10000',
    is_nullable   => 0,
  },
  "protect_group_cast",
  {
    data_type     => 'boolean',
    default_value => \'true',
    is_nullable   => 0,
  },
  "protect_user_cast",
  {
    data_type     => 'boolean',
    default_value => \'true',
    is_nullable   => 0,
  },
  "name",
  { data_type => "character varying", is_nullable => 0 },
  "display_name",
  { data_type => "character varying", is_nullable => 0 },
  "notification_markdown",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->uuid_columns('curse_id');
__PACKAGE__->set_primary_key('curse_id');
__PACKAGE__->resultset_attributes( { order_by => ['priority'] } );

__PACKAGE__->has_many
	(
	'member_curses',
	'HiveWeb::Schema::Result::MemberCurse',
	{ 'foreign.curse_id' => 'self.curse_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->has_many
	(
	'curse_actions',
	'HiveWeb::Schema::Result::CurseAction',
	{ 'foreign.curse_id' => 'self.curse_id' },
	{ cascade_copy => 0, cascade_delete => 0 },
	);

__PACKAGE__->many_to_many('members', 'member_curses', 'member');

sub admin_class
	{
	return __PACKAGE__ . '::Admin';
	}

sub TO_JSON
	{
	my $self = shift;

	return
		{
		curse_id              => $self->curse_id(),
		name                  => $self->name(),
		display_name          => $self->display_name(),
		notification          => markdown($self->notification_markdown()),
		notification_markdown => $self->notification_markdown(),
		};
	}

__PACKAGE__->meta->make_immutable;
1;

package HiveWeb::Schema::Result::Curse::Admin;

use strict;
use warnings;
use base qw/HiveWeb::Schema::Result::Curse/;
use Text::Markdown 'markdown';

__PACKAGE__->table('curse');

sub TO_JSON
	{
	my $self    = shift;
	my $actions = $self->curse_actions();
	my @actions;

	while (my $action = $actions->next())
		{
		push (@actions,
			{
			curse_action_id => $action->curse_action_id(),
			path            => $action->path(),
			action          => $action->action(),
			message         => $action->message(),
			});
		}

	return
		{
		curse_id              => $self->curse_id(),
		name                  => $self->name(),
		display_name          => $self->display_name(),
		notification          => markdown($self->notification_markdown()),
		notification_markdown => $self->notification_markdown(),
		protect_group_cast    => $self->protect_group_cast() ? \1 : \0,
		protect_user_cast     => $self->protect_user_cast() ? \1 : \0,
		priority              => $self->priority(),
		actions               => \@actions,
		};
	}
1;
