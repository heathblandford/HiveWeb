package HiveWeb::Controller::API::Storage;
use Moose;
use namespace::autoclean;

use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	$c->detach('list');
	}

sub list :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $out = $c->stash()->{out};
	$out->{response} = \0;

	my $user     = $c->user() || return;
	my @slots    = $user->list_slots();
	my @requests = $user->requests()->search({ hidden => 'f' })->all();

	$out->{slots}    = \@slots;
	$out->{requests} = \@requests;
	$out->{response} = \1;
	}

sub relinquish :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in  = $c->stash()->{in};
	my $out = $c->stash()->{out};
	$out->{response} = \0;

	my $user = $c->user() || return;

	my $slot = $c->model('DB::StorageSlot')->find($in->{slot_id});
	if (!$slot)
		{
		$out->{data} = "Could not find slot \"$in->{slot_id}\".";
		return;
		}
	if ($slot->member_id() ne $c->user()->member_id())
		{
		$out->{data} = 'This slot does not belong to you.';
		return;
		}

	$out->{response} = \1;
	try
		{
		$c->model('DB')->txn_do(sub
			{
			$user->create_related('changed_audits',
				{
				change_type        => 'relinquish_slot',
				notes              => 'Relinquished slot ' . $slot->slot_id(),
				changing_member_id => $user->member_id(),
				}) || die $!;
			$slot->update({ member_id => undef }) || die $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not relinquish slot.';
		};
	}

sub hide :Local :Args(0)
	{
	my ($self, $c) = @_;

	my $in  = $c->stash()->{in};
	my $out = $c->stash()->{out};
	$out->{response} = \0;

	my $user = $c->user() || return;

	my $request = $c->model('DB::StorageRequest')->find($in->{request_id});
	if (!$request)
		{
		$out->{data} = "Could not find request \"$in->{request_id}\".";
		return;
		}
	if ($request->member_id() ne $c->user()->member_id())
		{
		$out->{data} = 'This request does not belong to you.';
		return;
		}
	if ($request->status() ne 'accepted' && $request->status() ne 'rejected')
		{
		$out->{data} = 'This request has not been finalized.';
		return;
		}

	$out->{response} = \1;
	try
		{
		$c->model('DB')->txn_do(sub
			{
			$user->create_related('changed_audits',
				{
				change_type        => 'hide_request',
				notes              => 'Hid request ' . $request->request_id(),
				changing_member_id => $user->member_id(),
				}) || die $!;
			$request->update({ hidden => 't' }) || die $!;
			});
		}
	catch
		{
		$out->{response} = \0;
		$out->{data}     = 'Could not relinquish slot.';
		};
	}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;