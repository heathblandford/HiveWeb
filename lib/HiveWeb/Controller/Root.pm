package HiveWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Net::SMTP;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub auto :Private
	{
	my ($self, $c) = @_;

	$c->stash()->{extra_css} = [];
	}

sub index :Path :Args(0)
	{
	my ($self, $c) = @_;

	my $items = $c->model('DB::Item')->search({}, { order_by => 'me.display_name' });
	my $temps = [];
	while (my $item = $items->next())
		{
		my $temp = $item->search_related('temp_logs', {}, { order_by => { -desc => 'create_time' } })->first();
		if ($temp)
			{
			push (@$temps, { name => $item->display_name(), value => ($temp->temperature() / 10) });
			}
		}

	if ($c->user() && $c->user()->is_admin())
		{
		my @accesses = $c->model('DB::AccessLog')->search({}, { order_by => { -desc => 'me.access_time' }, rows => 10 });
		$c->stash()->{accesses} = \@accesses;
		}

	$c->stash(
		{
		template => 'index.tt',
		temps    => $temps,
		});
	}

sub login :Local
	{
	my ($self, $c) = @_;

	if ($c->request()->method() eq 'GET')
		{
		$c->stash()->{template} = 'login.tt';
		return;
		}
	
	my $params = $c->request()->params();

	my $auth          = {};
	$auth->{email}    = $params->{email};
	$auth->{password} = $params->{password};
	my $user = $c->authenticate($auth);
	my $log  = $c->model('DB::SignInLog')->create(
		{
		email     => $params->{email},
		valid     => $user ? 1 : 0,
		member_id => $user ? $user->member_id() : undef,
		remote_ip => $c->request()->address(),
		}) || die $!;
	if ($user)
		{
		$c->response()->redirect($c->uri_for('/'));
		}
	else
		{
		$c->stash()->{template} = 'login.tt';
		$c->stash()->{msg} = 'The username or password were invalid.';
		$c->response->status(403);
		}
	}

sub logout :Local
	{
	my ($self, $c) = @_;

	$c->logout();
	$c->response()->redirect($c->uri_for('/'));
	}

sub forgot :Local
	{
	my $self     = shift;
	my $c        = shift;
	my $token_id = shift;
	my $stash    = $c->stash();

	if ($token_id)
		{
		my $token = $c->model('DB::ResetToken')->find($token_id);
		$stash->{template} = 'forgot_token.tt';
		$stash->{token}    = $token;
		return;
		}

	if ($c->request()->method() eq 'GET')
		{
		$stash->{template} = 'forgot.tt';
		return;
		}

	my $params = $c->request()->params();
	my $email  = $params->{email};

	my $member = $c->model('DB::Member')->find({ email => $email });

	if ($member)
		{
		$c->log()->debug('Sending mail.');

		my $config = $c->config()->{email};
		my $forgot = $config->{forgot};
		my $token  = $member->create_related('reset_tokens', { valid => 1 });
		my $to     = $member->email();
		my $from   = $config->{from};
		my $stash  =
			{
			token  => $token,
			member => $member,
			};

		my $body = $c->view('TT')->render($c, $forgot->{temp_plain}, $stash);

		my $smtp = Net::SMTP->new(%{$config->{'Net::SMTP'}});
		die "Could not connect to server\n"
			if !$smtp;

		if (exists($config->{auth}))
			{
			$smtp->auth($from, $config->{auth})
				|| die "Authentication failed!\n";
			}

		$smtp->mail('<' . $from . ">\n");
		$smtp->to('<' . $to . ">\n");
		$smtp->data();
		$smtp->datasend('From: "' . $config->{from_name} . '" <' . $from . ">\n");
		$smtp->datasend('To: "' . $member->fname() . ' ' . $member->lname() . '" <' . $to . ">\n");
		$smtp->datasend('Subject: ' . $forgot->{subject} . "\n");
		$smtp->datasend("\n");
		$smtp->datasend($body . "\n");
		$smtp->dataend();
		$smtp->quit();
		}

	$stash->{email}    = $email;
	$stash->{template} = 'forgot_sent.tt';
	}

sub forgot_password :Local
	{
	my $self     = shift;
	my $c        = shift;
	my $token_id = shift;
	my $stash    = $c->stash();
	my $params   = $c->request()->params();
	my $token    = $c->model('DB::ResetToken')->find($token_id);

	$token = undef
		if ($token && !$token->valid());

	$stash->{token}    = $token;
	$stash->{template} = 'forgot_token.tt';

	return
		if (!$token || $c->request()->method() eq 'GET');

	my $member   = $token->member();
	my $password = $params->{password1};

	if ($password ne $params->{password2})
		{
		$stash->{message} = 'The passwords do not match.';
		return;
		}

	$c->model('DB')->txn_do(sub
		{
		$member->set_password($password);
		$token->update({ valid => 0 });
		});

	$stash->{template} = 'forgot_updated.tt';
	}

sub default :Path
	{
	my ( $self, $c ) = @_;
	
	$c->stash()->{template} = '404.tt';
	$c->response->status(404);
	}

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Greg Arnold

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
