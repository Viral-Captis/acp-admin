require 'rails_helper'

describe 'Member sessions' do
  before { Capybara.app_host = 'http://membres.ragedevert.test' }

  it 'creates a new session from email' do
    member = create(:member, emails: 'thibaud@thibaud.gg, john@doe.com')

    visit '/'
    expect(current_path).to eq '/login'
    expect(page).to have_content 'Merci de vous authentifier pour accèder à votre compte.'

    fill_in 'Votre email', with: 'thibaud@thibaud.gg'
    click_button 'Envoyer'

    session = member.sessions.last

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      to: 'thibaud@thibaud.gg',
      template: 'member-login-fr',
      template_data: {
        action_url: %r{/sessions/#{session.token}}
      }))

    expect(current_path).to eq '/login'
    expect(page).to have_content 'Merci! Un email vient de vous être envoyé.'

    visit "/sessions/#{session.token}"

    expect(current_path).to eq '/'
    expect(page).to have_content 'Vous êtes maintenant connecté.'

    delete_session(member)
    visit '/'

    expect(current_path).to eq '/login'
    expect(page).to have_content "Merci de vous authentifier pour accèder à votre compte."
  end

  it 'sends login help when email is not found' do
    visit '/'
    expect(current_path).to eq '/login'

    fill_in 'Votre email', with: 'unknown@member.com'
    click_button 'Envoyer'

    expect(email_adapter.deliveries.size).to eq 1
    expect(email_adapter.deliveries.first).to match(hash_including(
      to: 'unknown@member.com',
      template: 'member-login-help-fr',
      template_data: {}))

    expect(current_path).to eq '/login'
    expect(page).to have_content 'Merci! Un email vient de vous être envoyé.'
  end

  it 'does not accept old session when not logged in' do
    old_session = create(:session, created_at: 1.hour.ago)

    visit "/sessions/#{old_session.token}"

    expect(current_path).to eq '/login'
    expect(page).to have_content "Votre lien de connexion n'est plus valide, merci d'en demander un nouveau."
  end

  it 'handles old session when already logged in' do
    member = create(:member)
    login(member)
    old_session = create(:session, member: member, created_at: 1.hour.ago)

    visit "/sessions/#{old_session.token}"

    expect(current_path).to eq '/'
    expect(page).to have_content 'Vous êtes déjà connecté.'
  end

  it 'logout expired session' do
    member = create(:member)
    login(member)
    member.sessions.last.update!(created_at: 1.year.ago)

    visit '/'

    expect(current_path).to eq '/login'
    expect(page).to have_content "Votre session a expirée, merci de vous authentifier à nouveau."

    visit '/'

    expect(current_path).to eq '/login'
    expect(page).to have_content "Merci de vous authentifier pour accèder à votre compte."
  end

  it 'redirects old member token' do
    member = create(:member, token: 'token12345')

    visit "/#{member.reload.token}"

    expect(current_path).to eq '/login'
    expect(page).to have_content "Votre session a expirée, merci de vous authentifier à nouveau."
  end
end
