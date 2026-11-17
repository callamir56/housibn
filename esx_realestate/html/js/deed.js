const Deed = {
    isOpen: false,
    busy: false,
    generation: 0,
    mode: 'manage',
    picking: false,
    request: function(action) {
        if (this.busy) return;
        this.busy = true;
        const current = this.generation;
        $('.property-deed .deed-sign, .property-deed .deed-item').prop('disabled', true);
        $('.property-deed .deed-status').text('Loading...');
        $.post(`https://${GetParentResourceName()}/deed:request`, JSON.stringify({action}))
            .done(data => {
                if (!this.isOpen || current !== this.generation) return;
                this.busy = false;
                if (!data || !data.ok) { $('.property-deed .deed-status').text(data?.reason || 'Deed unavailable.'); $('.property-deed .deed-sign, .property-deed .deed-item').prop('disabled', false); return; }
                if (action === 'item') { $('.property-deed .deed-status').text(data.message || 'Done.'); $('.property-deed .deed-item').prop('disabled', false); return; }
                this.render(data);
            })
            .fail(() => { if (this.isOpen && current === this.generation) { this.busy = false; $('.property-deed .deed-status').text('Deed unavailable.'); $('.property-deed .deed-sign, .property-deed .deed-item').prop('disabled', false); } });
    },
    render: function(data) {
        const box = $('.property-deed');
        box.find('.deed-id').text(`#${data.id}`);
        box.find('.deed-name').text(data.name || '');
        box.find('.deed-address').text(data.address || 'Not available');
        box.find('.deed-owner').text(data.owner || 'Unknown owner');
        box.find('.deed-issued').text(`Viewed ${data.issued || ''}`);
        box.find('.deed-signature').text(data.signature || '');
        box.find('.deed-signed-date').text(data.signedAt ? `· ${data.signedAt}` : '');
        box.find('.deed-sign').toggle(this.mode === 'manage' && !data.signature).prop('disabled', false);
        box.find('.deed-item').toggle(this.mode === 'manage' && !!data.signature).prop('disabled', false);
        box.find('.deed-status').text('');
    },
    open: function() {
        if (this.isOpen) return;
        this.isOpen = true; this.busy = false; this.generation++; this.mode = 'manage';
        $('.property-deed .deed-back').text('Back');
        $('.property-deed .deed-signature, .property-deed .deed-owner, .property-deed .deed-name, .property-deed .deed-address, .property-deed .deed-id, .property-deed .deed-signed-date, .property-deed .deed-issued').text('');
        $('.housing_manage').hide(); $('.property-deed').fadeIn(150);
        this.request('view');
    },
    hide: function() { this.isOpen = false; this.busy = false; this.generation++; $('.property-deed').hide(); },
    close: function() {
        if (!this.isOpen) return;
        const shared = this.mode !== 'manage';
        this.hide();
        if (shared) {
            if (currentMenu === 'deed_share') currentMenu = null;
            $.post(`https://${GetParentResourceName()}/deedShare:close`, JSON.stringify({}));
        } else if (currentMenu === 'housing_manage') $('.housing_manage').fadeIn(120);
    },
    Pick: function(message) {
        this.picking = true;
        const list = $('.deed-picker-list').empty(); $('.deed-picker-status').text('');
        (Array.isArray(message.data) ? message.data : []).forEach(player => {
            $('<button type="button"></button>').text(`${player.name || 'Player'} · ${player.id}`).on('click', function() {
                $('.deed-picker-list button').prop('disabled', true);
                $.post(`https://${GetParentResourceName()}/deedShare:choose`, JSON.stringify({id: player.id}))
                    .done(result => { if (!result?.ok) { $('.deed-picker-status').text(result?.reason || 'Try again.'); $('.deed-picker-list button').prop('disabled', false); } })
                    .fail(() => { $('.deed-picker-status').text('Try again.'); $('.deed-picker-list button').prop('disabled', false); });
            }).appendTo(list);
        });
        $('.deed-picker').fadeIn(120); currentMenu = 'deed_picker';
    },
    closePicker: function() {
        if (!this.picking) return;
        this.picking = false; $('.deed-picker').hide(); if (currentMenu === 'deed_picker') currentMenu = null;
        $.post(`https://${GetParentResourceName()}/deedShare:cancel`, JSON.stringify({}));
    },
    Show: function(message) {
        this.picking = false; $('.deed-picker').hide();
        this.mode = message.role === 'owner' ? 'owner' : 'viewer';
        this.isOpen = true; this.busy = false; this.generation++;
        $('.property-deed .deed-back').text('Close');
        this.render(message.data || {}); $('.property-deed').fadeIn(150); currentMenu = 'deed_share';
    },
    ForceClose: function() {
        this.picking = false; $('.deed-picker').hide();
        if (this.mode !== 'manage') this.hide();
        if (currentMenu === 'deed_share' || currentMenu === 'deed_picker') currentMenu = null;
    }
};
$('.property-deed .deed-sign').on('click', function() { Deed.request('sign'); });
$('.property-deed .deed-item').on('click', function() { Deed.request('item'); });
$('.property-deed .deed-back, .property-deed .deed-close-x').on('click', function() { Deed.close(); });
$('.deed-picker-close').on('click', function() { Deed.closePicker(); });
