{extends file="page.tpl"}
{block name="content"}
{if !$paypal->isLoaded()}
<div id="errorbox">
    <h1>{_T string="- ERROR -"}</h1>
    <p>{_T string="<strong>Payment coult not work</strong>: An error occured (that has been logged) while loading Paypal preferences from database.<br/>Please report the issue to the staff." domain="paypal"}</p>
    <p>{_T string="Our apologies for the annoyance :("}</p>
</div>
{elseif $paypal->getId() eq null}
    <div id="errorbox">
        <h1>{_T string="- ERROR -"}</h1>
        <p>{_T string="Paypal id has not been defined. Please ask an administrator to add it from plugin preferences." domain="paypal"}</p>
    </div>
{else}
    {if !$paypal->areAmountsLoaded()}
<div id="warningbox">
    <h1>{_T string="- WARNING -"}</h1>
    <p>{_T string="Predefined amounts cannot be loaded, that is not a critical error." domain="paypal"}</p>
</div>
    {/if}
    <section>
<form action="{if constant('GALETTE_MODE') eq 'DEV'}https://www.sandbox.paypal.com/fr/cgi-bin/webscr{else}https://www.paypal.com/cgi-bin/webscr{/if}" method="post" id="paypal">
    {* To read more about variables, see https://cms.paypal.com/es/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_html_Appx_websitestandard_htmlvariables#id08A6HI0709B *}
    <!-- Paypal required variables -->
    {if isset($custom)}
    <input type="hidden" name="custom" value="{$custom}"/>
    {/if}
    <input type="hidden" name="cmd" value="_xclick"/>
    <input type="hidden" name="business" value="{$paypal->getId()}"/>
    <input type="hidden" name="lc" value="FR"/>{*language of the login or sign-up page*}{* FIXME: parameter *}
    <input type="hidden" name="currency_code" value="EUR"/>{*transaction currency*}{* FIXME: parameter? *}
    <input type="hidden" name="button_subtype" value="services"/>
    <input type="hidden" name="no_note" value="1"/>
    <input type="hidden" name="no_shipping" value="1"/>
    {*<input type="hidden" name="bn" value="PP-BuyNowBF:btn_buynowCC_LG.gif:NonHostedGuest"/><!-- notfound :( -->*}
    <!-- Paypal dialogs -->
    <input type="hidden" name="return" value="{$current_url}{path_for name="paypal_success"}"/>
    <input type="hidden" name="rm" value="2"/>{*Send POST values back to Galette after payment. Will be sent to return url above*}
    <input type="hidden" name="charset" value="UTF-8"/>
    <input type="hidden" name="image_url" value="{$current_url}{path_for name="logo"}"/>
    <input type="hidden" name="cancel_return" value="{$current_url}{path_for name="paypal_cancelled"}"/>
    <input type="hidden" name="notify_url" value="{$current_url}{path_for name="paypal_notify"}"/>
    <input type="hidden" name="cbt" value="{_T string="Go back to %s's website to complete your inscription." domain="paypal" pattern="/%s/" replace=$preferences->pref_nom}"/>

    <fieldset id="paypal_form">
        <legend class="ui-state-active ui-corner-top">
    {if $amounts|@count eq 0}
            {_T string="Enter payment reason" domain="paypal"}
    {elseif $amounts|@count eq 1}
            {_T string="Payment reason" domain="paypal"}
    {elseif $amounts|@count gt 1}
            {_T string="Select an payment reason" domain="paypal"}
    {/if}
        </legend>

    {if $paypal->areAmountsLoaded()}
        <div id="amounts">
        {if $amounts|@count gt 0}
            <input type="hidden" name="item_name" id="item_name" value="{if $login->isLogged()}{_T string="annual fee"}{else}{_T string="donation in money"}{/if}"/>
            {foreach from=$amounts key=k item=amount name=amounts}
            {if $smarty.foreach.amounts.index != 0}<br/>{/if}
            <input type="radio" name="item_number" id="in{$k}" value="{$k}"{if $smarty.foreach.amounts.index == 0} checked="checked"{/if}/>
            <label for="in{$k}"><span id="in{$k}_name">{$amount['name']}</span>
                {if $amount['amount'] gt 0}
                (<span id="in{$k}_amount">{$amount['amount']|string_format:"%.2f"}</span> €){* TODO: parametize currency *}
                {/if}
            </label>
            {/foreach}
        {else}
            <label for="item_name">{_T string="Payment reason:" domain="paypal"}</label>
            <input type="text" name="item_name" id="item_name" value="{if $login->isLogged()}{_T string="annual fee"}{else}{_T string="donation in money"}{/if}"/>
        {/if}
        </div>
    {else}
        <p>{_T string="No predefined amounts have been configured yet." domain="paypal"}</p>
    {/if}

        <p>
    {if $paypal->areAmountsLoaded() and $amounts|@count gt 0}
            <noscript>
                <br/><span class="required">{_T string="WARNING: If you enter an amount below, make sure that it is not lower than the amount of the option you've selected." domain="paypal"}</span>
            </noscript>
    {/if}
        </p>
        <p>
            <label for="amount">{_T string="Amount"}</label>
			<!--
				OPITUX
				Je change le type de l'input pour corriger le bug d'un caractère accentué, d'une virgule ou d'un € renseigné par l'adhérent
				ancien input : <input type="text" name="amount" id="amount" value="{if $amounts|@count > 0}{$amounts[1]['amount']}{else}20{/if}"/>
			-->
            <input type="number" name="amount" id="amount" step="1" value="{if $amounts|@count > 0}{$amounts[1]['amount']}{else}20{/if}" required="required" />
        </p>
    </fieldset>

    <div class="button-container">
        <input type="submit" name="submit" value="{_T string="Validate"}"/>
    </div>
</form>
        </section>
{/if}
{/block}

{block name="javascripts"}

<!-- OPITUX -->
<script>

$(window).on('load', function() {

$( "#amount" ).after( "<div id='paypalbox' class='warningbox' style='margin:10px 0;'><b>Attention&nbsp;:</b><br />Pour une cotisation libre ou une cotisation famille, merci de renseigner le champ \"Montant\" ci-dessus.<br /><br /><b>La cotisation minimale est fixée à 5 euros</b>.</div>" );

});

$("input[name='item_number']").change(function(){
    var selected_radio = $("input[name='item_number']:checked").val();
	if (selected_radio == '2' || selected_radio == '3'){
        $( ".warningbox" ).remove();
        $( ".errorbox" ).remove();
    	$( '#amount' ).val('');
        $( '#amount' ).attr("placeholder", "Votre cotisation");
        $( '#amount' ).focus();
        $( "#amount" ).after( "<div id='paypalbox' class='warningbox' style='margin:10px 0;'><b>Attention&nbsp;:</b><br />Pour une cotisation libre ou une cotisation famille, merci de renseigner le champ \"Montant\" ci-dessus.<br /><br /><b>La cotisation minimale est fixée à 5 euros</b>.</div>" );
        return false;
    }
	else if (selected_radio == '8' || selected_radio == '9')
	{
        $( ".warningbox" ).remove();
        $( ".errorbox" ).remove();
    	$( '#amount' ).val('');
        $( '#amount' ).attr("placeholder", "Votre cotisation");
        $( '#amount' ).focus();
        $( "#amount" ).after( "<div id='paypalbox' class='warningbox' style='margin:10px 0;'><b>Attention&nbsp;:</b><br />Pour une cotisation libre ou famille + <b>inscription au Camp Itinérant 2019</b>, merci de renseigner le champ \"Montant\" ci-dessus.<br /><br /><b>La cotisation minimale est fixée à 5 euros + 5 euros par participant au Camp Itinérant.</b></div>" );
        return false;
    }
    else if (selected_radio == '5')
    {
        $( ".warningbox" ).remove();
        $( ".errorbox" ).remove();
    	$( '#amount' ).val('');
        $( '#amount' ).attr("placeholder", "Votre donation");
        $( '#amount' ).focus();
    }
    else
    {
        $( ".warningbox" ).remove();
        $( ".errorbox" ).remove();
    }
});

$(document).ready(function(){
    $("input[name='submit']").click(function(){
    var value = $("#amount").val();
	var selected_radio = $("input[name='item_number']:checked").val();
		if (selected_radio == '2' || selected_radio == '3') {
	    	if( value < 5 ) {
	    	$("#paypalbox").attr('class', 'errorbox');
	//        $( ".warningbox" ).remove();
	//        $( ".errorbox" ).remove();
	//        $( "#amount" ).after( "<div class='errorbox' style='margin:10px 0;'><b>Attention&nbsp;:</b><br /> Si vous optez pour une cotisation libre, merci renseigner le champ \"Montant\" ci-dessus<br />La cotisation minimal est fixée à 5 euros.</div>" );
	        return false;
	        }
		} else {
			if( value < 10 ) {
	    	$("#paypalbox").attr('class', 'errorbox');
	//        $( ".warningbox" ).remove();
	//        $( ".errorbox" ).remove();
	//        $( "#amount" ).after( "<div class='errorbox' style='margin:10px 0;'><b>Attention&nbsp;:</b><br /> Si vous optez pour une cotisation libre, merci renseigner le champ \"Montant\" ci-dessus<br />La cotisation minimal est fixée à 5 euros.</div>" );
	        return false;
	        }
		}
    });
});
</script>
<!-- OPITUX -->

{if $paypal->isLoaded() and $paypal->getId() neq null and $paypal->areAmountsLoaded()}
<script type="text/javascript">
    $(function() {
        $('input[name="item_number"]').change(function(){
            var _amount = parseFloat($('#' + this.id + '_amount').text());
            var _name = $('#' + this.id + '_name').text();
            $('#item_name').val(_name);
            if ( _amount != '' && !isNaN(_amount) ) {
                $('#amount').val(_amount);
            }
        });
    {if $amounts|@count gt 0}
        $('#paypal').submit(function(){
            var _checked = $('input:checked');
            if (_checked.length == 0 ) {
                alert("{_T string="You have to select an option"}");
                return false;
            } else {
                var _current_amount = parseFloat($('#amount').val());
                var _amount = parseFloat($('#' + _checked[0].id + '_amount').text());
                if ( isNaN(_current_amount) ) {
                    alert("{_T string="Please enter an amount." domain="paypal" escape="js"}");
                    return false;
                } else if ( !isNaN(_amount) && _current_amount < _amount ) {
                    alert("{_T string="The amount you've entered is lower than the minimum amount for the selected option.\\nPlease choose another option or change the amount." domain="paypal" escape="js"}");
                    return false;
                }
            }
            return true;
        });
    {/if}
    });
</script>
{/if}
{/block}
