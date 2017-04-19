package HiveWeb::Controller::API;
use Moose;
use namespace::autoclean;

use JSON;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

HiveWeb::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub find_member :Private
	{
	my $c        = shift;
	my $badge_no = shift;
	my $badge    = $c->model('DB::Badge')->find( { badge_number => $badge_no } );

	return $badge->member()
		if (defined($badge));
	return $c->model('DB::Member')->find( { accesscard => $badge_no } );
	}

sub has_access :Private
	{
	my $c        = shift;
	my $badge_no = shift;
	my $iname    = shift;
	my $item     = $c->model('DB::Item')->find( { name => $iname } );
	my $member   = find_member($c, $badge_no);
	
	return "Invalid badge"
		if (!defined($member));
	return "Invalid item"
		if (!defined($item));
	return "Locked out"
		if ($member->is_lockedout());
	
	my $access = $member->has_access($item);
	
	# Log the access
	$c->model('DB::AccessLog')->create(
		{
		member_id => $member->member_id(),
		item_id   => $item->item_id(),
		granted   => $access ? 1 : 0,
		});
	
	return $access ? undef : "Access denied";
	}


sub begin :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{in} = $c->req()->body_data();
	$c->stash()->{out} = {};
	$c->stash()->{view} = $c->view('JSON');
	}

sub end :Private
	{
	my ($self, $c) = @_;

	$c->detach($c->stash()->{view});
	}

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;
	
	$c->response->body('Matched HiveWeb::Controller::API in API.');
	}

sub access :Local
	{
	my ($self, $c) = @_;
	my $in     = $c->stash()->{in};
	my $out    = $c->stash()->{out};
	my $device = $c->model('DB::Device')->find({ name => $in->{device} });
	my $data   = $in->{data};
	my $view   = $c->view('ChecksummedJSON');

	if (!defined($device))
		{
		$out->{response} = JSON->false();
		$out->{error} = 'Cannot find device.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}
	
	$c->stash()->{view}   = $view;
	$c->stash()->{device} = $device;
	
	my $shasum = $view->make_hash($c, $data);
	if ($shasum ne uc($in->{checksum}))
		{
		$out->{response} = JSON->false();
		$out->{error} = 'Invalid checksum.';
		$c->response()->status(400)
			if ($data->{http});
		return;
		}
	
	$out->{response} = JSON->true();
	$out->{random_response} = $data->{random_response};
	my $operation = lc($data->{operation} // 'access');
	if ($operation eq 'access')
		{
		my $badge  = $data->{badge};
		my $item   = $data->{location} // $data->{item};
		my $access = has_access($c, $badge, $item);		
		my $d_i    = $device
			->search_related('device_items')
			->search_related('item', { name => $item } );
		
		if ($d_i->count() < 1)
			{
			$out->{access} = JSON->false();
			$out->{error} = "Device not authorized for " . $item;
			$c->response()->status(401)
				if ($data->{http});
			}
		elsif (defined($access))
			{
			$out->{access} = JSON->false();
			$out->{error} = $access;
			$c->response()->status(401)
				if ($data->{http});
			}
		else
			{
			$out->{access} = JSON->true();
			}
		}
	elsif ($operation eq 'vend')
		{
		my $member = find_member($c, $data->{badge});

		if (!$member)
			{
			$out->{vend} = JSON->false();
			$out->{error} = "Cannot find member associated with this badge.";
			return;
			}

		if (!$member->do_vend())
			{
			$out->{vend} = JSON->false();
			$out->{error} = "You have no soda credits.";
			return;
			}

		$out->{vend} = JSON->true();
		$out->{error} = "Have a soda!";
		}
	else
		{
		$out->{response} = JSON->false();
		$out->{error} = 'Invalid operation.';
		$c->response()->status(400)
			if ($data->{http});
		}
	} 

=encoding utf8

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
